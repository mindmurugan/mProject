import Foundation
import SwiftData

/// A trip taken by one of you, surfaced in the "Global View" travel hub
/// so the person at home can see live itinerary segments and a time-zone
/// slider showing the traveler's local hours.
@Model
public final class Trip {
    public var id: UUID = UUID()
    public var title: String = ""
    public var startDate: Date = Date.now
    public var endDate: Date?

    /// IANA identifier, e.g. "Asia/Kolkata", used to drive the time zone slider.
    public var destinationTimeZoneIdentifier: String?
    public var destinationName: String?
    public var notes: String?

    public var household: Household?
    public var traveler: HouseholdMember?

    @Relationship(deleteRule: .cascade, inverse: \ItinerarySegment.trip)
    public var segments: [ItinerarySegment]?

    public init(
        title: String = "",
        startDate: Date = .now,
        endDate: Date? = nil,
        destinationTimeZoneIdentifier: String? = nil,
        destinationName: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.destinationTimeZoneIdentifier = destinationTimeZoneIdentifier
        self.destinationName = destinationName
    }
}
