import Foundation
import SwiftData

@Model
final class Wine {
    var name: String
    var producer: Producer?
    var varietals: [String]
    var wineTypeRaw: String
    var region: String?
    var appellation: String?
    var country: String?
    /// UPC/EAN from the back label, when scannable. Fast-path key for "have I seen this before".
    var barcode: String?
    /// Text embedding of `normalizedProfile` used for nearest-neighbor similarity search.
    var profileEmbedding: [Double]?

    @Relationship(deleteRule: .cascade, inverse: \Vintage.wine)
    var vintages: [Vintage] = []

    var wineType: WineType {
        get { WineType(rawValue: wineTypeRaw) ?? .unknown }
        set { wineTypeRaw = newValue.rawValue }
    }

    init(
        name: String,
        producer: Producer? = nil,
        varietals: [String] = [],
        wineType: WineType = .unknown,
        region: String? = nil,
        appellation: String? = nil,
        country: String? = nil,
        barcode: String? = nil
    ) {
        self.name = name
        self.producer = producer
        self.varietals = varietals
        self.wineTypeRaw = wineType.rawValue
        self.region = region
        self.appellation = appellation
        self.country = country
        self.barcode = barcode
    }

    /// Normalized text used both for fuzzy string matching and as embedding input.
    var normalizedProfile: String {
        var parts = [name]
        if let producerName = producer?.name { parts.append(producerName) }
        parts.append(contentsOf: varietals)
        if let region { parts.append(region) }
        parts.append(wineType.rawValue)
        return parts.joined(separator: " ").lowercased()
    }

    /// Deep links to public rating sites — used whenever a live score can't be fetched.
    func searchURL(for source: RatingSource) -> URL? {
        let query = [producer?.name, name].compactMap { $0 }.joined(separator: " ")
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        switch source {
        case .vivino:
            return URL(string: "https://www.vivino.com/search/wines?q=\(encoded)")
        case .cellarTracker:
            return URL(string: "https://www.cellartracker.com/list.asp?szSearch=\(encoded)")
        case .jamesSuckling:
            return URL(string: "https://www.jamessuckling.com/?s=\(encoded)")
        case .other:
            return nil
        }
    }
}
