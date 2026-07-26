import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Tasks", systemImage: "checklist") {
                TaskListView()
            }
            Tab("Inbox", systemImage: "tray.and.arrow.down.fill") {
                InboxView()
            }
            Tab("Boards", systemImage: "square.grid.2x2.fill") {
                BoardsView()
            }
            Tab("Travel", systemImage: "globe.americas.fill") {
                TravelHubView()
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
    }
}

#Preview {
    RootView()
}
