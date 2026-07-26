import Foundation
import Vision
import UIKit

struct ScannedLabel {
    /// Raw recognized text lines, top-to-bottom, as Vision saw them.
    var textLines: [String]
    /// Any UPC/EAN barcodes found on the label — the fast path for exact re-identification.
    var barcodes: [String]

    var joinedText: String { textLines.joined(separator: "\n") }
}

/// Wraps Vision's on-device text and barcode recognition. Runs entirely on-device — no
/// network call, no per-scan cost, works offline.
actor VisionScanService {

    func scanLabel(from image: UIImage) async throws -> ScannedLabel {
        guard let cgImage = image.cgImage else {
            throw VisionScanError.invalidImage
        }

        async let text = recognizeText(cgImage: cgImage)
        async let barcodes = recognizeBarcodes(cgImage: cgImage)

        return ScannedLabel(textLines: try await text, barcodes: try await barcodes)
    }

    /// Scans a wider frame (a full menu page) and returns every text line, left-to-right
    /// reading order preserved, so the caller can segment it into per-wine candidates.
    func scanMenu(from image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw VisionScanError.invalidImage
        }
        return try await recognizeText(cgImage: cgImage)
    }

    private func recognizeText(cgImage: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func recognizeBarcodes(cgImage: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNBarcodeObservation] ?? []
                let codes = observations.compactMap { $0.payloadStringValue }
                continuation.resume(returning: codes)
            }
            request.symbologies = [.ean13, .ean8, .upce, .code128]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

enum VisionScanError: Error {
    case invalidImage
}
