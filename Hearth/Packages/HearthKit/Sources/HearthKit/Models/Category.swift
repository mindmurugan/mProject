import Foundation
import SwiftData

/// A smart category such as "Home Renovation", "Groceries", or "Wishlist".
/// Populated by seed data (`isSystemDefault == true`) and by on-device
/// Foundation Models suggestions accepted from the Drop Zone inbox.
@Model
public final class Category {
    public var id: UUID = UUID()
    public var name: String = ""
    public var colorHex: String = "#0A84FF"
    public var systemIconName: String = "tag.fill"
    public var isSystemDefault: Bool = false
    public var createdAt: Date = Date.now

    public var household: Household?

    @Relationship(deleteRule: .nullify, inverse: \TaskItem.category)
    public var tasks: [TaskItem]?

    @Relationship(deleteRule: .nullify, inverse: \CapturedItem.category)
    public var capturedItems: [CapturedItem]?

    @Relationship(deleteRule: .nullify, inverse: \Board.category)
    public var boards: [Board]?

    public init(
        name: String = "",
        colorHex: String = "#0A84FF",
        systemIconName: String = "tag.fill",
        isSystemDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.systemIconName = systemIconName
        self.isSystemDefault = isSystemDefault
        self.createdAt = .now
    }
}
