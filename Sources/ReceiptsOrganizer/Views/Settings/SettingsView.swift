import SwiftUI
import SwiftData

struct SettingsView: View {

    @Query private var receipts: [Receipt]
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAllAlert = false
    @State private var notificationAuthStatus: String = "Checking..."
    @State private var appleIntelligenceStatus: String = "Checking..."

    var body: some View {
        Form {
            Section("Apple Intelligence") {
                LabeledContent("Status", value: appleIntelligenceStatus)
                    .foregroundStyle(appleIntelligenceStatus == "Available" ? .green : .secondary)
            }

            Section("Notifications") {
                LabeledContent("Permission", value: notificationAuthStatus)
                NavigationLink("Notification Settings") {
                    notificationSettingsView
                }
            }

            Section("Data") {
                LabeledContent("Total Receipts", value: "\(receipts.count)")
                LabeledContent(
                    "With Warranties",
                    value: "\(receipts.filter { $0.warrantyInfo != nil }.count)"
                )
                Button("Delete All Receipts", role: .destructive) {
                    showDeleteAllAlert = true
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Requires", value: "iOS 18 + Apple Intelligence")
            }
        }
        .navigationTitle("Settings")
        .alert("Delete All Receipts?", isPresented: $showDeleteAllAlert) {
            Button("Delete", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(receipts.count) receipts and their warranties.")
        }
        .task {
            await checkStatuses()
        }
    }

    private var notificationSettingsView: some View {
        Form {
            Section("Warranty Notifications") {
                Text("You'll receive notifications 30 days before, 7 days before, and on the day a warranty expires.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Open System Notification Settings") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
    }

    private func checkStatuses() async {
        // Check notification authorization
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized: notificationAuthStatus = "Authorized"
        case .denied: notificationAuthStatus = "Denied"
        case .notDetermined: notificationAuthStatus = "Not Requested"
        case .provisional: notificationAuthStatus = "Provisional"
        case .ephemeral: notificationAuthStatus = "Ephemeral"
        @unknown default: notificationAuthStatus = "Unknown"
        }

        // Check Apple Intelligence availability
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            appleIntelligenceStatus = "Available"
        case .unavailable(let reason):
            appleIntelligenceStatus = "Unavailable: \(reason.localizedDescription)"
        }
    }

    private func deleteAll() {
        for receipt in receipts {
            modelContext.delete(receipt)
        }
        try? modelContext.save()
    }
}
