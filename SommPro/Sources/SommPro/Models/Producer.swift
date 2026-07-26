import Foundation
import SwiftData

@Model
final class Producer {
    var name: String
    var region: String?
    var country: String?
    var foundedYear: Int?
    /// Cached, human-readable background written by the enrichment pipeline (Gemini or on-device).
    var story: String?
    var wikidataID: String?
    var lastEnrichedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Wine.producer)
    var wines: [Wine] = []

    init(name: String, region: String? = nil, country: String? = nil) {
        self.name = name
        self.region = region
        self.country = country
    }
}
