import Foundation

enum WineType: String, Codable, CaseIterable, Identifiable {
    case red
    case white
    case rose
    case sparkling
    case dessert
    case fortified
    case orange
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rose: "Rosé"
        default: rawValue.capitalized
        }
    }
}
