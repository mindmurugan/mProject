import Foundation

/// Relative urgency for a `TaskItem`. Stored directly as a SwiftData attribute.
public enum TaskPriority: String, Codable, CaseIterable, Sendable {
    case low
    case normal
    case high

    public var sortWeight: Int {
        switch self {
        case .low: return 0
        case .normal: return 1
        case .high: return 2
        }
    }
}

/// The kind of raw payload a Drop Zone share extension captured before triage.
public enum CapturedContentType: String, Codable, CaseIterable, Sendable {
    case link
    case image
    case file
    case text
}

/// The kind of entry inside a `Trip`'s itinerary.
public enum SegmentKind: String, Codable, CaseIterable, Sendable {
    case flight
    case lodging
    case activity
    case transport
    case other
}
