import Vision
import UIKit

actor OCRService {

    enum OCRError: LocalizedError {
        case imageConversionFailed
        case recognitionFailed(Error)
        case noTextFound

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed: return "Could not process the image."
            case .recognitionFailed(let e): return "OCR failed: \(e.localizedDescription)"
            case .noTextFound: return "No readable text was found in the document."
            }
        }
    }

    func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageConversionFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error))
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { obs in
                    obs.topCandidates(1).first?.string
                }

                guard !lines.isEmpty else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                continuation.resume(returning: lines.joined(separator: "\n"))
            }

            // .accurate is slower but critical for receipts with small print
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.customWords = [
                "warranty", "receipt", "purchase", "expiration",
                "invoice", "serial", "model", "SKU", "UPC"
            ]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error))
            }
        }
    }

    func recognizeText(inPages images: [UIImage]) async throws -> String {
        var allText: [String] = []
        for image in images {
            let text = try await recognizeText(in: image)
            allText.append(text)
        }
        return allText.joined(separator: "\n\n--- Page Break ---\n\n")
    }
}
