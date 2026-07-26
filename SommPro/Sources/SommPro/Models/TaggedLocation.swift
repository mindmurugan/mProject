import Foundation

/// A lightweight, `Codable`/SwiftData-storable location tag captured automatically via
/// `LocationTaggingService` at scan time — no server round trip required.
struct TaggedLocation: Codable, Hashable {
    var name: String?
    var latitude: Double
    var longitude: Double

    var displayName: String { name ?? "\(latitude), \(longitude)" }
}
