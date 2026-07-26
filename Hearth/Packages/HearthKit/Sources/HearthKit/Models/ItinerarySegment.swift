import Foundation
import SwiftData

/// A single flight, hotel stay, or activity within a `Trip`.
@Model
public final class ItinerarySegment {
    public var id: UUID = UUID()
    public var kind: SegmentKind = SegmentKind.flight
    public var title: String = ""
    public var startDate: Date = Date.now
    public var endDate: Date?
    public var location: String?
    public var confirmationCode: String?
    public var notes: String?

    public var trip: Trip?

    public init(
        kind: SegmentKind = .flight,
        title: String = "",
        startDate: Date = .now,
        endDate: Date? = nil,
        location: String? = nil,
        confirmationCode: String? = nil
    ) {
        self.id = UUID()
        self.kind = kind
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.confirmationCode = confirmationCode
    }
}
