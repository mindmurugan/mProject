import Foundation
import SwiftData

/// A visual inspiration canvas (e.g. "Living Room Renovation") that pins
/// photos annotated by `VisionExtractionService` with OCR text and parsed
/// dimensions/measurements.
@Model
public final class Board {
    public var id: UUID = UUID()
    public var title: String = ""
    public var boardDescription: String?
    public var createdAt: Date = Date.now

    @Attribute(.externalStorage)
    public var coverImageData: Data?

    public var household: Household?
    public var category: Category?
    public var createdBy: HouseholdMember?

    @Relationship(deleteRule: .cascade, inverse: \BoardItem.board)
    public var items: [BoardItem]?

    public init(title: String = "", boardDescription: String? = nil) {
        self.id = UUID()
        self.title = title
        self.boardDescription = boardDescription
        self.createdAt = .now
    }
}
