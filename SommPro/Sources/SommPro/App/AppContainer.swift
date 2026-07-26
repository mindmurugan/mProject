import Foundation
import SwiftData

enum AppContainer {
    /// CloudKit-backed container so the cellar and history sync free across the user's
    /// iPhone and iPad via their own iCloud account — no server to run or pay for.
    static let shared: ModelContainer = {
        let schema = Schema([
            Producer.self,
            Wine.self,
            Vintage.self,
            Bottle.self,
            TastingEvent.self,
            ExternalRating.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create SommPro model container: \(error)")
        }
    }()
}
