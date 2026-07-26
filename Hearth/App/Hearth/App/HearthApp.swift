import SwiftUI
import SwiftData
import HearthKit

@main
struct HearthApp: App {
    let container: ModelContainer
    @StateObject private var sharingCoordinator = CloudSharingCoordinator()
    @StateObject private var currentMemberResolver = CurrentMemberResolver()

    init() {
        do {
            container = try HearthSchema.makeContainer()
        } catch {
            fatalError("Failed to create Hearth's ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .task { await currentMemberResolver.refresh() }
                .environmentObject(sharingCoordinator)
                .environmentObject(currentMemberResolver)
        }
        .modelContainer(container)
    }
}
