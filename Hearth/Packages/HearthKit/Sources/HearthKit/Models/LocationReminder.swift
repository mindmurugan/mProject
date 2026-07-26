import Foundation
import SwiftData

/// A geofence (e.g. "Hardware Store", "Grocery Store") that, when entered by
/// either partner's device, should trigger a high-priority local notification
/// listing whichever `TaskItem`s are tagged to it. One geofence can back
/// several tasks (a single "Grocery Store" region covers the whole shopping
/// list); each task points at at most one reminder.
@Model
public final class LocationReminder {
    public var id: UUID = UUID()
    public var title: String = ""
    public var latitude: Double = 0
    public var longitude: Double = 0
    public var radiusMeters: Double = 150
    public var isActive: Bool = true
    public var createdAt: Date = Date.now

    public var household: Household?

    @Relationship(deleteRule: .nullify, inverse: \TaskItem.locationReminder)
    public var tasks: [TaskItem]?

    public init(
        title: String = "",
        latitude: Double = 0,
        longitude: Double = 0,
        radiusMeters: Double = 150
    ) {
        self.id = UUID()
        self.title = title
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.isActive = true
        self.createdAt = .now
    }
}
