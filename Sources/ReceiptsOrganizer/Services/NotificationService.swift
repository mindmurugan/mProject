import UserNotifications
import SwiftData
import Foundation

@MainActor
final class NotificationService {

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Scheduling

    func scheduleWarrantyNotifications(for receipt: Receipt, context: ModelContext) async {
        guard let warranty = receipt.warrantyInfo,
              let expirationDate = warranty.expirationDate,
              expirationDate > Date()
        else { return }

        await cancelNotifications(for: receipt)

        let triggers: [(NotificationTriggerType, Int)] = [
            (.thirtyDaysBefore, -30),
            (.sevenDaysBefore, -7),
            (.onExpiration, 0)
        ]

        for (triggerType, dayOffset) in triggers {
            guard let triggerDate = Calendar.current.date(
                byAdding: .day, value: dayOffset, to: expirationDate
            ), triggerDate > Date() else { continue }

            let identifier = notificationIdentifier(for: receipt.id, triggerType: triggerType)
            let content = makeContent(for: triggerType, receipt: receipt, expirationDate: expirationDate)

            // DateComponents trigger survives reboots and DST transitions
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
                let record = NotificationRecord(
                    notificationIdentifier: identifier,
                    scheduledDate: triggerDate,
                    triggerType: triggerType
                )
                receipt.notificationRecords.append(record)
                context.insert(record)
            } catch {
                // Notifications are additive; a scheduling failure must not block the save flow
                print("[NotificationService] Failed to schedule \(triggerType.rawValue): \(error)")
            }
        }
    }

    func cancelNotifications(for receipt: Receipt) async {
        let identifiers = receipt.notificationRecords.map(\.notificationIdentifier)
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    // MARK: - Launch recovery
    // iOS silently drops pending notifications when the 64-notification system limit is hit.
    // Rescheduling on every cold launch recovers from that without user intervention.

    func rescheduleAllPendingNotifications(receipts: [Receipt], context: ModelContext) async {
        for receipt in receipts {
            await scheduleWarrantyNotifications(for: receipt, context: context)
        }
    }

    // MARK: - Helpers

    private func notificationIdentifier(
        for receiptID: UUID,
        triggerType: NotificationTriggerType
    ) -> String {
        "warranty.\(receiptID.uuidString).\(triggerType.rawValue)"
    }

    private func makeContent(
        for triggerType: NotificationTriggerType,
        receipt: Receipt,
        expirationDate: Date
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "WARRANTY_EXPIRY"
        let formattedDate = expirationDate.formatted(date: .abbreviated, time: .omitted)

        switch triggerType {
        case .thirtyDaysBefore:
            content.title = "Warranty Expiring in 30 Days"
            content.body = "\(receipt.productName) warranty expires on \(formattedDate)."
            content.sound = .default
        case .sevenDaysBefore:
            content.title = "Warranty Expiring in 7 Days"
            content.body = "\(receipt.productName) warranty expires on \(formattedDate)."
            content.sound = .default
        case .onExpiration:
            content.title = "Warranty Expired Today"
            content.body = "The warranty for \(receipt.productName) has expired."
            content.sound = .defaultCritical
        }

        return content
    }
}
