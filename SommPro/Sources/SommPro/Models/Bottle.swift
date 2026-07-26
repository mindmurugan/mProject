import Foundation
import SwiftData

/// A physical bottle in the user's possession — cellar inventory, independent of whether
/// it's ever been opened (see `TastingEvent` for that).
@Model
final class Bottle {
    var vintage: Vintage?
    var quantity: Int
    var purchaseDate: Date
    var purchasePrice: Double?
    var currencyCode: String
    var purchaseLocation: TaggedLocation?
    /// Free-text cellar position, e.g. "Rack B, Shelf 2".
    var cellarSlot: String?
    var acquiredViaModeRaw: String
    var photoData: Data?
    var isConsumed: Bool

    var acquiredViaMode: ScanMode {
        get { ScanMode(rawValue: acquiredViaModeRaw) ?? .shop }
        set { acquiredViaModeRaw = newValue.rawValue }
    }

    init(
        vintage: Vintage? = nil,
        quantity: Int = 1,
        purchaseDate: Date = .now,
        purchasePrice: Double? = nil,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        purchaseLocation: TaggedLocation? = nil,
        cellarSlot: String? = nil,
        acquiredViaMode: ScanMode = .shop
    ) {
        self.vintage = vintage
        self.quantity = quantity
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.currencyCode = currencyCode
        self.purchaseLocation = purchaseLocation
        self.cellarSlot = cellarSlot
        self.acquiredViaModeRaw = acquiredViaMode.rawValue
        self.isConsumed = false
    }
}
