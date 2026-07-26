import Foundation
import SwiftData

/// The single CloudKit-shared root of the object graph.
///
/// Every other top-level model (`HouseholdMember`, `TaskItem`, `Category`, `Board`,
/// `Trip`, `CapturedItem`, `LocationReminder`) holds an optional relationship back
/// to exactly one `Household`. CloudKit sharing (`CKShare`) operates on the record
/// graph reachable from a single shared root object, so creating one `Household`
/// per couple and sharing it once (see `CloudSharingCoordinator`) is what makes
/// every task/board/trip created afterwards show up on both partners' devices
/// without re-sharing anything individually.
@Model
public final class Household {
    public var id: UUID = UUID()
    public var name: String = "Our Home"
    public var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \HouseholdMember.household)
    public var members: [HouseholdMember]?

    @Relationship(deleteRule: .cascade, inverse: \Category.household)
    public var categories: [Category]?

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.household)
    public var tasks: [TaskItem]?

    @Relationship(deleteRule: .cascade, inverse: \CapturedItem.household)
    public var inbox: [CapturedItem]?

    @Relationship(deleteRule: .cascade, inverse: \Board.household)
    public var boards: [Board]?

    @Relationship(deleteRule: .cascade, inverse: \Trip.household)
    public var trips: [Trip]?

    @Relationship(deleteRule: .cascade, inverse: \LocationReminder.household)
    public var locationReminders: [LocationReminder]?

    public init(name: String = "Our Home") {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
    }
}
