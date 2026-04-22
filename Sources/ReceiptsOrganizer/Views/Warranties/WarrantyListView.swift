import SwiftUI
import SwiftData

struct WarrantyListView: View {

    @Query private var receipts: [Receipt]

    private var receiptsWithWarranties: [Receipt] {
        receipts
            .filter { $0.warrantyInfo != nil }
            .sorted {
                let d0 = $0.warrantyInfo?.daysUntilExpiry ?? Int.max
                let d1 = $1.warrantyInfo?.daysUntilExpiry ?? Int.max
                return d0 < d1
            }
    }

    private var expiringSoon: [Receipt] {
        receiptsWithWarranties.filter {
            guard let days = $0.warrantyInfo?.daysUntilExpiry else { return false }
            return days >= 0 && days <= 30
        }
    }

    private var active: [Receipt] {
        receiptsWithWarranties.filter {
            guard let days = $0.warrantyInfo?.daysUntilExpiry else { return false }
            return days > 30
        }
    }

    private var expired: [Receipt] {
        receiptsWithWarranties.filter {
            $0.warrantyInfo?.isExpired == true
        }
    }

    var body: some View {
        Group {
            if receiptsWithWarranties.isEmpty {
                ContentUnavailableView(
                    "No Warranties",
                    systemImage: "shield.slash",
                    description: Text("Add receipts with warranty information to track them here.")
                )
            } else {
                list
            }
        }
        .navigationTitle("Warranties")
    }

    private var list: some View {
        List {
            if !expiringSoon.isEmpty {
                Section("Expiring Soon") {
                    ForEach(expiringSoon) { receipt in
                        NavigationLink(value: receipt) {
                            warrantyRow(receipt)
                        }
                    }
                }
            }

            if !active.isEmpty {
                Section("Active") {
                    ForEach(active) { receipt in
                        NavigationLink(value: receipt) {
                            warrantyRow(receipt)
                        }
                    }
                }
            }

            if !expired.isEmpty {
                Section("Expired") {
                    ForEach(expired) { receipt in
                        NavigationLink(value: receipt) {
                            warrantyRow(receipt)
                        }
                    }
                }
            }
        }
        .navigationDestination(for: Receipt.self) { receipt in
            ReceiptDetailView(receipt: receipt)
        }
    }

    private func warrantyRow(_ receipt: Receipt) -> some View {
        HStack(spacing: 12) {
            Image(systemName: receipt.category.systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(receipt.productName.isEmpty ? "Unnamed Product" : receipt.productName)
                    .font(.headline)
                    .lineLimit(1)
                if let expiry = receipt.warrantyInfo?.expirationDate {
                    Text("Expires \(expiry.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let warranty = receipt.warrantyInfo {
                ExpirationBadgeView(status: warranty.expirationStatus)
            }
        }
        .padding(.vertical, 2)
    }
}
