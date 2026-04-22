import SwiftData
import Foundation

@Model
final class Receipt {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    var productName: String
    var vendorName: String
    var purchaseDate: Date?
    var purchasePrice: Decimal?
    var currencyCode: String
    var category: ReceiptCategory
    var rawOCRText: String?
    var userNotes: String?

    @Relationship(deleteRule: .cascade)
    var warrantyInfo: WarrantyInfo?

    @Relationship(deleteRule: .cascade)
    var attachments: [DocumentAttachment]

    @Relationship(deleteRule: .cascade)
    var notificationRecords: [NotificationRecord]

    init(
        productName: String = "",
        vendorName: String = "",
        category: ReceiptCategory = .other
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.productName = productName
        self.vendorName = vendorName
        self.currencyCode = "USD"
        self.category = category
        self.attachments = []
        self.notificationRecords = []
    }
}

enum ReceiptCategory: String, Codable, CaseIterable {
    case electronics
    case appliances
    case furniture
    case clothing
    case automotive
    case health
    case tools
    case other

    var displayName: String {
        switch self {
        case .electronics: return "Electronics"
        case .appliances: return "Appliances"
        case .furniture: return "Furniture"
        case .clothing: return "Clothing"
        case .automotive: return "Automotive"
        case .health: return "Health"
        case .tools: return "Tools"
        case .other: return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .electronics: return "laptopcomputer"
        case .appliances: return "washer"
        case .furniture: return "sofa"
        case .clothing: return "tshirt"
        case .automotive: return "car"
        case .health: return "heart.text.square"
        case .tools: return "wrench.and.screwdriver"
        case .other: return "archivebox"
        }
    }
}
