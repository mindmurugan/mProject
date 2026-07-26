import SwiftUI
import SwiftData

@main
struct SommProApp: App {

    private let enrichmentCoordinator: EnrichmentCoordinator

    init() {
        let gemini: GeminiService? = GeminiAPIKeyStore.load().map {
            GeminiService(configuration: GeminiConfiguration(apiKey: $0))
        }
        enrichmentCoordinator = EnrichmentCoordinator(gemini: gemini)
    }

    var body: some Scene {
        WindowGroup {
            RootView(enrichmentCoordinator: enrichmentCoordinator)
                .modelContainer(AppContainer.shared)
        }
    }
}
