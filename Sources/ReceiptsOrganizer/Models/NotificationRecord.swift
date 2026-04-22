import SwiftData
import Foundation

@Model
final class NotificationRecord {
    var id: UUID
    var notificationIdentifier: String
    var scheduledDate: Date
    var triggerType: NotificationTriggerType
    var wasDelivered: Bool

    var receipt: Receipt?

    init(
        notificationIdentifier: String,
        scheduledDate: Date,
        triggerType: NotificationTriggerType
    ) {
        self.id = UUID()
        self.notificationIdentifier = notificationIdentifier
        self.scheduledDate = scheduledDate
        self.triggerType = triggerType
        self.wasDelivered = false
    }
}

enum NotificationTriggerType: String, Codable {
    case thirtyDaysBefore
    case sevenDaysBefore
    case onExpiration
}
