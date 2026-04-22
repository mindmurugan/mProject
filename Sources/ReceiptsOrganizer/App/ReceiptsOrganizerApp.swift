import SwiftUI
import SwiftData

@main
struct ReceiptsOrganizerApp: App {

    @StateObject private var notificationService = NotificationService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(AppContainer.shared)
                .task {
                    await notificationService.requestAuthorization()
                    await rescheduleNotificationsOnLaunch()
                }
        }
    }

    @MainActor
    private func rescheduleNotificationsOnLaunch() async {
        let context = AppContainer.shared.mainContext
        let descriptor = FetchDescriptor<Receipt>()
        guard let receipts = try? context.fetch(descriptor) else { return }
        await notificationService.rescheduleAllPendingNotifications(
            receipts: receipts,
            context: context
        )
    }
}
