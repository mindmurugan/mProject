import Foundation
import SwiftData

/// A raw drop from the "Drop Zone" share extension (a link, photo, file, or
/// plain text) sitting in the shared inbox before either of you triages it
/// into a `TaskItem`, pins it to a `Board`, or discards it.
///
/// `suggestedCategoryName` / `suggestedCategoryConfidence` are filled in by
/// `CategorizationService` (on-device Foundation Models) as soon as the item
/// lands, so the triage UI can offer a one-tap "Yes, file it under Groceries"
/// action instead of making either of you pick from a menu.
@Model
public final class CapturedItem {
    public var id: UUID = UUID()
    public var createdAt: Date = Date.now
    public var contentType: CapturedContentType = CapturedContentType.text

    /// Shared plain text, or the URL string for `.link` items.
    public var rawText: String?

    /// Original page/content title, when the extension could read one.
    public var sourceTitle: String?

    /// Image payload for `.image` captures. External storage keeps large
    /// blobs out of the row itself; SwiftData syncs it to CloudKit as a
    /// `CKAsset` automatically.
    @Attribute(.externalStorage)
    public var imageData: Data?

    /// Suggested category name from on-device categorization, pending confirmation.
    public var suggestedCategoryName: String?
    public var suggestedCategoryConfidence: Double?

    public var isTriaged: Bool = false

    public var household: Household?
    public var addedBy: HouseholdMember?
    public var category: Category?

    /// Set once triage promotes this capture into an actual to-do.
    public var convertedToTask: TaskItem?

    public init(
        contentType: CapturedContentType = .text,
        rawText: String? = nil,
        sourceTitle: String? = nil,
        imageData: Data? = nil
    ) {
        self.id = UUID()
        self.createdAt = .now
        self.contentType = contentType
        self.rawText = rawText
        self.sourceTitle = sourceTitle
        self.imageData = imageData
        self.isTriaged = false
    }
}
