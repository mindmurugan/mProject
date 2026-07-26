import SwiftUI

struct CellarRowView: View {
    let bottle: Bottle

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(bottle.vintage?.wine?.name ?? "Unknown wine")
                    .font(.headline)
                Spacer()
                if bottle.quantity > 1 {
                    Text("×\(bottle.quantity)")
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                if let producer = bottle.vintage?.wine?.producer?.name {
                    Text(producer)
                }
                if let vintage = bottle.vintage {
                    Text(vintage.displayYear)
                }
                if let type = bottle.vintage?.wine?.wineType {
                    Text(type.displayName)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                if let location = bottle.purchaseLocation {
                    Label(location.displayName, systemImage: "mappin.and.ellipse")
                }
                if let price = bottle.purchasePrice {
                    Text(price, format: .currency(code: bottle.currencyCode))
                }
                if let slot = bottle.cellarSlot {
                    Label(slot, systemImage: "archivebox")
                }
            }
            .font(.caption)
            .foregroundStyle(.tertiary)

            if let rating = averagePersonalRating {
                Label("\(rating, specifier: "%.1f")/5 from your tastings", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 2)
    }

    private var averagePersonalRating: Double? {
        let ratings = bottle.vintage?.tastingEvents.compactMap(\.personalRating) ?? []
        guard !ratings.isEmpty else { return nil }
        return ratings.reduce(0, +) / Double(ratings.count)
    }
}
