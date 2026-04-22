import SwiftUI

struct RootView: View {

    @State private var selectedTab: AppTab = .receipts

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ReceiptListView()
            }
            .tabItem {
                Label("Receipts", systemImage: "doc.text")
            }
            .tag(AppTab.receipts)

            NavigationStack {
                WarrantyListView()
            }
            .tabItem {
                Label("Warranties", systemImage: "shield.checkered")
            }
            .tag(AppTab.warranties)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(AppTab.settings)
        }
    }
}

enum AppTab: Hashable {
    case receipts, warranties, settings
}
