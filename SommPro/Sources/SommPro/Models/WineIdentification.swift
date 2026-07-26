import Foundation

/// The parsed result of "what wine is this", produced by either the Gemini enrichment
/// service or the on-device Foundation Models fallback from raw OCR text/barcode input.
/// Never persisted directly — it's used to find-or-create `Producer`/`Wine`/`Vintage` rows.
struct WineIdentification: Codable, Equatable {
    var producerName: String?
    var wineName: String
    var vintageYear: Int?
    var varietals: [String]
    var region: String?
    var country: String?
    var wineType: WineType
    /// One line, one candidate — used when a menu scan contains several wines.
    var sourceMenuLine: String?
    /// 0...1, how confident the identifying model was in this parse.
    var confidence: Double

    static let unknown = WineIdentification(
        producerName: nil,
        wineName: "Unknown wine",
        vintageYear: nil,
        varietals: [],
        region: nil,
        country: nil,
        wineType: .unknown,
        sourceMenuLine: nil,
        confidence: 0
    )
}

/// Educational background text about a producer or region, written by the enrichment
/// pipeline from grounded facts (Gemini web-aware answer, or Wikidata + on-device rewrite).
struct WineEducation: Codable, Equatable {
    var producerStory: String?
    var regionNotes: String?
    var grapeNotes: String?
    var foodPairingSuggestion: String?
    var generatedOffline: Bool
}
