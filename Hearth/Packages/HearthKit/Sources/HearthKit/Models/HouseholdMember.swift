import Foundation
import SwiftData

/// A person who can be assigned tasks or attributed as the creator of content.
///
/// Deliberately modeled as data rather than a hardcoded "Me" / "Saral" enum:
/// because the two of you use separate iCloud accounts, "Me" is relative to
/// whichever device is looking at the record. `cloudKitUserRecordName` stores
/// the CloudKit participant identity (captured when the share is created or
/// accepted, see `CloudSharingCoordinator`) so the UI layer can compute
/// "is this member the current device's owner?" at read time instead of
/// persisting a boolean that would be wrong on one of the two devices.
@Model
public final class HouseholdMember {
    public var id: UUID = UUID()
    public var name: String = ""
    public var colorHex: String = "#8E8E93"
    public var systemIconName: String = "person.fill"

    /// `CKRecord.ID.recordName` of this person's iCloud user record, once known.
    public var cloudKitUserRecordName: String?
    public var createdAt: Date = Date.now

    public var household: Household?

    @Relationship(deleteRule: .nullify, inverse: \TaskItem.assignee)
    public var assignedTasks: [TaskItem]?

    @Relationship(deleteRule: .nullify, inverse: \CapturedItem.addedBy)
    public var capturedItems: [CapturedItem]?

    @Relationship(deleteRule: .nullify, inverse: \Board.createdBy)
    public var createdBoards: [Board]?

    @Relationship(deleteRule: .nullify, inverse: \Trip.traveler)
    public var trips: [Trip]?

    public init(
        name: String = "",
        colorHex: String = "#8E8E93",
        systemIconName: String = "person.fill",
        cloudKitUserRecordName: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.systemIconName = systemIconName
        self.cloudKitUserRecordName = cloudKitUserRecordName
        self.createdAt = .now
    }
}
