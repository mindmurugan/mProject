import Foundation
import SwiftData

enum RatingSource: String, Codable, CaseIterable {
    case vivino
    case cellarTracker
    case jamesSuckling
    case other

    var displayName: String {
        switch self {
        case .vivino: "Vivino"
        case .cellarTracker: "CellarTracker"
        case .jamesSuckling: "James Suckling"
        case .other: "Other"
        }
    }
}

/// A best-effort snapshot of a public rating. `score` is nil when scraping failed or was
/// skipped, in which case `url` still lets the user open the source directly.
@Model
final class ExternalRating {
    var sourceRaw: String
    var score: Double?
    /// The scale the score is reported on, e.g. 5.0 for Vivino, 100.0 for James Suckling.
    var scaleMax: Double?
    var reviewCount: Int?
    var url: URL?
    var fetchedAt: Date
    var wasFetchedLive: Bool

    var vintage: Vintage?

    var source: RatingSource {
        get { RatingSource(rawValue: sourceRaw) ?? .other }
        set { sourceRaw = newValue.rawValue }
    }

    init(
        source: RatingSource,
        score: Double? = nil,
        scaleMax: Double? = nil,
        reviewCount: Int? = nil,
        url: URL? = nil,
        wasFetchedLive: Bool = false,
        fetchedAt: Date = .now
    ) {
        self.sourceRaw = source.rawValue
        self.score = score
        self.scaleMax = scaleMax
        self.reviewCount = reviewCount
        self.url = url
        self.wasFetchedLive = wasFetchedLive
        self.fetchedAt = fetchedAt
    }
}
