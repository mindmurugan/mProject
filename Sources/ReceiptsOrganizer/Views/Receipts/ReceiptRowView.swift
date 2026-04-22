import SwiftUI

struct ReceiptRowView: View {

    let receipt: Receipt

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: receipt.category.systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(receipt.productName.isEmpty ? "Unnamed Product" : receipt.productName)
                    .font(.headline)
                    .lineLimit(1)
                Text(receipt.vendorName.isEmpty ? "Unknown Vendor" : receipt.vendorName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let warranty = receipt.warrantyInfo {
                ExpirationBadgeView(status: warranty.expirationStatus)
            }
        }
        .padding(.vertical, 2)
    }
}
