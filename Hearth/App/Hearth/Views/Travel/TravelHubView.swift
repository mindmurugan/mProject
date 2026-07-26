import SwiftUI
import SwiftData
import HearthKit

/// "Global View": live itineraries plus a slider that lets the person at
/// home drag through the day and see what time it is for the traveling
/// partner, so you're not doing timezone math before every call.
struct TravelHubView: View {
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]

    private var activeTrip: Trip? {
        trips.first { trip in
            guard let end = trip.endDate else { return trip.startDate <= .now }
            return trip.startDate <= .now && end >= .now
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HearthBackground()

                if let trip = activeTrip {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            TimeZoneSliderCard(trip: trip)

                            ForEach(trip.segments?.sorted(by: { $0.startDate < $1.startDate }) ?? []) { segment in
                                ItinerarySegmentRow(segment: segment)
                            }
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "No active trip",
                        systemImage: "globe.americas",
                        description: Text("Add a trip to see live itineraries and time zones here.")
                    )
                }
            }
            .navigationTitle("Travel")
        }
    }
}

private struct TimeZoneSliderCard: View {
    let trip: Trip
    @State private var hourOffset: Double = 0

    private var destinationTimeZone: TimeZone {
        trip.destinationTimeZoneIdentifier.flatMap(TimeZone.init(identifier:)) ?? .current
    }

    private var previewDate: Date {
        Date.now.addingTimeInterval(hourOffset * 3600)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(trip.destinationName ?? trip.title)
                .font(.headline)

            HStack {
                timeColumn(label: "Home", timeZone: .current)
                Spacer()
                timeColumn(label: trip.destinationName ?? "Away", timeZone: destinationTimeZone)
            }

            Slider(value: $hourOffset, in: -12...12, step: 0.5)
            Text(hourOffset == 0 ? "Right now" : String(format: "%+.1f hours from now", hourOffset))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .glassSurface(cornerRadius: 20)
    }

    private func timeColumn(label: String, timeZone: TimeZone) -> some View {
        VStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(previewDate, format: .dateTime.hour().minute().timeZone(timeZone))
                .font(.title2.monospacedDigit())
        }
    }
}

private struct ItinerarySegmentRow: View {
    let segment: ItinerarySegment

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(segment.title).font(.subheadline.weight(.medium))
                if let location = segment.location {
                    Text(location).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(segment.startDate, format: .dateTime.month().day().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .glassSurface(cornerRadius: 14)
    }

    private var iconName: String {
        switch segment.kind {
        case .flight: return "airplane"
        case .lodging: return "bed.double.fill"
        case .activity: return "figure.walk"
        case .transport: return "car.fill"
        case .other: return "mappin.circle.fill"
        }
    }
}
