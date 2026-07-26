import Foundation

/// The three ways a user can point the camera at a wine.
enum ScanMode: String, Codable, CaseIterable, Identifiable {
    case drink
    case shop
    case menu

    var id: String { rawValue }

    var title: String {
        switch self {
        case .drink: "Drink"
        case .shop: "Shop"
        case .menu: "Menu"
        }
    }

    var systemImage: String {
        switch self {
        case .drink: "wineglass"
        case .shop: "cart"
        case .menu: "menucard"
        }
    }

    var subtitle: String {
        switch self {
        case .drink: "Scan a bottle you're about to open"
        case .shop: "Scan several bottles on a shelf"
        case .menu: "Scan a restaurant wine list"
        }
    }
}
