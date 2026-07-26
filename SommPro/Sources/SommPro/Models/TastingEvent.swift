import Foundation
import SwiftData

/// A single "I tasted this" moment — the record that builds the drinking history and feeds
/// the personal-rating-driven similarity engine.
@Model
final class TastingEvent {
    var vintage: Vintage?
    var date: Date
    var modeRaw: String
    /// Personal rating, 0...5 in half-point steps, independent of any external scale.
    var personalRating: Double?
    var notes: String?
    var tags: [String]
    var location: TaggedLocation?
    var photoData: Data?
    /// Links back to the bottle consumed, when the tasting followed a cellar bottle.
    var bottle: Bottle?

    var mode: ScanMode {
        get { ScanMode(rawValue: modeRaw) ?? .drink }
        set { modeRaw = newValue.rawValue }
    }

    init(
        vintage: Vintage? = nil,
        date: Date = .now,
        mode: ScanMode = .drink,
        personalRating: Double? = nil,
        notes: String? = nil,
        tags: [String] = [],
        location: TaggedLocation? = nil,
        bottle: Bottle? = nil
    ) {
        self.vintage = vintage
        self.date = date
        self.modeRaw = mode.rawValue
        self.personalRating = personalRating
        self.notes = notes
        self.tags = tags
        self.location = location
        self.bottle = bottle
    }
}
