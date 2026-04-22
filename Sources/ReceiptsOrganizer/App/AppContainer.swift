import SwiftData
import Foundation

enum AppContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            Receipt.self,
            WarrantyInfo.self,
            DocumentAttachment.self,
            NotificationRecord.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }()
}
