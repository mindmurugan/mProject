import Foundation
import SwiftData

/// A single pinned photo on a `Board`, enriched by the Vision framework.
@Model
public final class BoardItem {
    public var id: UUID = UUID()
    public var createdAt: Date = Date.now

    @Attribute(.externalStorage)
    public var imageData: Data?

    /// Raw text recognized by `VNRecognizeTextRequest`.
    public var extractedText: String?

    /// Best-effort dimension/measurement string parsed out of `extractedText`
    /// (e.g. "24in x 36in", "1.2m"), produced by `VisionExtractionService`.
    public var extractedDimensions: String?

    public var notes: String?
    public var sourceURL: String?

    public var board: Board?
    public var addedBy: HouseholdMember?

    public init(
        imageData: Data? = nil,
        extractedText: String? = nil,
        extractedDimensions: String? = nil,
        notes: String? = nil,
        sourceURL: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = .now
        self.imageData = imageData
        self.extractedText = extractedText
        self.extractedDimensions = extractedDimensions
        self.notes = notes
        self.sourceURL = sourceURL
    }
}
