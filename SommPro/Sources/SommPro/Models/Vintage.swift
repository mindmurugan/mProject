import Foundation
import SwiftData

@Model
final class Vintage {
    /// 0 represents a non-vintage wine (e.g. many Champagnes).
    var year: Int
    var wine: Wine?
    var abv: Double?
    /// Heuristic drink window, derived from wine type/region rather than a paid data source.
    var drinkWindowStart: Int?
    var drinkWindowEnd: Int?

    @Relationship(deleteRule: .cascade, inverse: \ExternalRating.vintage)
    var externalRatings: [ExternalRating] = []

    @Relationship(deleteRule: .cascade, inverse: \Bottle.vintage)
    var bottles: [Bottle] = []

    @Relationship(deleteRule: .cascade, inverse: \TastingEvent.vintage)
    var tastingEvents: [TastingEvent] = []

    init(year: Int, wine: Wine? = nil, abv: Double? = nil) {
        self.year = year
        self.wine = wine
        self.abv = abv
    }

    var displayYear: String { year == 0 ? "NV" : String(year) }
}
