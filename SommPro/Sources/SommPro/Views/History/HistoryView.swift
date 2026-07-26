import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \TastingEvent.date, order: .reverse) private var events: [TastingEvent]

    var body: some View {
        NavigationStack {
            List {
                if events.isEmpty {
                    ContentUnavailableView(
                        "No tastings yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Wines you rate in Drink or Menu mode show up here.")
                    )
                } else {
                    ForEach(events) { event in
                        HistoryRowView(event: event)
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

private struct HistoryRowView: View {
    let event: TastingEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(event.vintage?.wine?.name ?? "Unknown wine")
                    .font(.headline)
                Spacer()
                Text(event.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                if let producer = event.vintage?.wine?.producer?.name {
                    Text(producer)
                }
                if let vintage = event.vintage {
                    Text(vintage.displayYear)
                }
                Label(event.mode.title, systemImage: event.mode.systemImage)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let rating = event.personalRating {
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: starImage(for: index, rating: rating))
                    }
                }
                .font(.caption)
                .foregroundStyle(.yellow)
            }

            if let notes = event.notes, !notes.isEmpty {
                Text(notes)
                    .font(.callout)
            }

            if let location = event.location {
                Label(location.displayName, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if !event.tags.isEmpty {
                Text(event.tags.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private func starImage(for index: Int, rating: Double) -> String {
        let threshold = Double(index) + 1
        if rating >= threshold { return "star.fill" }
        if rating >= threshold - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}
