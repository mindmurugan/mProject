import SwiftUI
import SwiftData

@MainActor
@Observable
final class ReceiptListViewModel {

    var searchText: String = ""
    var selectedCategory: ReceiptCategory? = nil
    var sortOrder: SortOrder = .dateDescending

    enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case nameAscending = "Name (A-Z)"
        case expirationAscending = "Expiring Soon"
    }

    func filtered(_ receipts: [Receipt]) -> [Receipt] {
        var result = receipts

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.productName.lowercased().contains(query) ||
                $0.vendorName.lowercased().contains(query)
            }
        }

        switch sortOrder {
        case .dateDescending:
            result.sort { $0.createdAt > $1.createdAt }
        case .dateAscending:
            result.sort { $0.createdAt < $1.createdAt }
        case .nameAscending:
            result.sort { $0.productName < $1.productName }
        case .expirationAscending:
            result.sort {
                let d0 = $0.warrantyInfo?.daysUntilExpiry ?? Int.max
                let d1 = $1.warrantyInfo?.daysUntilExpiry ?? Int.max
                return d0 < d1
            }
        }

        return result
    }
}
