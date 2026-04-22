import SwiftData
import Foundation

@Model
final class WarrantyInfo {
    var id: UUID
    var expirationDate: Date?
    var warrantyTerms: String?
    var durationMonths: Int?
    var warrantyType: WarrantyType
    var providerName: String?
    var contactInfo: String?

    var receipt: Receipt?

    var isExpired: Bool {
        guard let expiry = expirationDate else { return false }
        return expiry < Date()
    }

    var daysUntilExpiry: Int? {
        guard let expiry = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiry).day
    }

    var expirationStatus: ExpirationStatus {
        guard let days = daysUntilExpiry else { return .noWarranty }
        if days < 0 { return .expired }
        if days <= 7 { return .critical }
        if days <= 30 { return .warning }
        return .valid
    }

    init() {
        self.id = UUID()
        self.warrantyType = .manufacturer
    }
}

enum WarrantyType: String, Codable, CaseIterable {
    case manufacturer
    case extended
    case creditCard
    case store
    case unknown

    var displayName: String {
        switch self {
        case .manufacturer: return "Manufacturer"
        case .extended: return "Extended"
        case .creditCard: return "Credit Card"
        case .store: return "Store"
        case .unknown: return "Unknown"
        }
    }
}

enum ExpirationStatus {
    case noWarranty
    case expired
    case critical   // ≤ 7 days
    case warning    // ≤ 30 days
    case valid

    var color: String {
        switch self {
        case .noWarranty: return "gray"
        case .expired: return "red"
        case .critical: return "orange"
        case .warning: return "yellow"
        case .valid: return "green"
        }
    }

    var label: String {
        switch self {
        case .noWarranty: return "No Warranty"
        case .expired: return "Expired"
        case .critical: return "Expiring Soon"
        case .warning: return "Expires Soon"
        case .valid: return "Active"
        }
    }
}
