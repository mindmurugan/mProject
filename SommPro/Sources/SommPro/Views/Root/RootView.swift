import SwiftUI

struct RootView: View {
    let enrichmentCoordinator: EnrichmentCoordinator

    var body: some View {
        TabView {
            ScannerView(enrichmentCoordinator: enrichmentCoordinator)
                .tabItem { Label("Scan", systemImage: "camera.viewfinder") }

            CellarView()
                .tabItem { Label("Cellar", systemImage: "square.stack.3d.up") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
