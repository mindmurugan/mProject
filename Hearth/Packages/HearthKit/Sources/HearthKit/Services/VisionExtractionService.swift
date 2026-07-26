import Foundation
#if canImport(Vision)
import Vision
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(UIKit)
import UIKit
#endif

/// What we pull out of a photo pinned to a `Board`.
public struct BoardImageExtraction: Sendable, Equatable {
    public let recognizedText: String?
    public let dimensionCandidate: String?

    public init(recognizedText: String?, dimensionCandidate: String?) {
        self.recognizedText = recognizedText
        self.dimensionCandidate = dimensionCandidate
    }
}

public protocol VisionExtractionService: Sendable {
    func extract(fromImageData data: Data) async throws -> BoardImageExtraction
}

#if canImport(Vision) && canImport(CoreGraphics)

/// Runs on-device OCR (`VNRecognizeTextRequest`) on a pinned inspiration photo
/// -- a furniture tag, a paint swatch, a fabric label -- and pulls out
/// anything that looks like a measurement so the board card can surface
/// "24in x 36in" without either of you retyping it.
public final class OnDeviceVisionExtractionService: VisionExtractionService {
    public init() {}

    public func extract(fromImageData data: Data) async throws -> BoardImageExtraction {
        guard let cgImage = Self.makeCGImage(from: data) else {
            return BoardImageExtraction(recognizedText: nil, dimensionCandidate: nil)
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let lines = (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }

        let text = lines.isEmpty ? nil : lines.joined(separator: "\n")
        let dimension = text.flatMap(Self.firstDimensionMatch)

        return BoardImageExtraction(recognizedText: text, dimensionCandidate: dimension)
    }

    /// Matches common measurement notations: `24in x 36in`, `24" x 36"`,
    /// `120cm`, `1.2m x 0.8m`. Good enough for a first pass; flag for manual
    /// correction rather than trusting it blindly.
    static func firstDimensionMatch(in text: String) -> String? {
        let pattern = #"(\d+(\.\d+)?\s?(in|inch|inches|cm|mm|m|ft|'|")\s?(x|×)\s?\d+(\.\d+)?\s?(in|inch|inches|cm|mm|m|ft|'|")?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let swiftRange = Range(match.range, in: text) else { return nil }
        return String(text[swiftRange])
    }

    private static func makeCGImage(from data: Data) -> CGImage? {
        #if canImport(UIKit)
        return UIImage(data: data)?.cgImage
        #else
        return nil
        #endif
    }
}

#endif

public struct NoOpVisionExtractionService: VisionExtractionService {
    public init() {}

    public func extract(fromImageData data: Data) async throws -> BoardImageExtraction {
        BoardImageExtraction(recognizedText: nil, dimensionCandidate: nil)
    }
}
