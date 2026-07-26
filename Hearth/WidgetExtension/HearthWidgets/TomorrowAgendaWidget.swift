import WidgetKit
import SwiftUI
import SwiftData
import HearthKit

/// StandBy isn't a separate API to target -- it's what iOS calls when it
/// renders your Lock Screen-style widgets (the `.accessoryRectangular` /
/// `.accessoryCircular` families) full-screen while the phone charges in
/// landscape. Supporting those families well *is* "building a StandBy view".
/// This widget summarizes tomorrow's shared agenda: tasks due tomorrow plus
/// any itinerary segment starting tomorrow.
struct TomorrowAgendaEntry: TimelineEntry {
    let date: Date
    let taskCount: Int
    let nextHeadline: String?
}

struct TomorrowAgendaProvider: TimelineProvider {
    func placeholder(in context: Context) -> TomorrowAgendaEntry {
        TomorrowAgendaEntry(date: .now, taskCount: 0, nextHeadline: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TomorrowAgendaEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TomorrowAgendaEntry>) -> Void) {
        let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
        completion(Timeline(entries: [makeEntry()], policy: .after(midnight)))
    }

    private func makeEntry() -> TomorrowAgendaEntry {
        guard let container = try? HearthSchema.makeContainer() else {
            return TomorrowAgendaEntry(date: .now, taskCount: 0, nextHeadline: nil)
        }
        let context = ModelContext(container)
        let calendar = Calendar.current
        let tomorrowStart = calendar.startOfDay(for: .now).addingTimeInterval(86_400)
        let tomorrowEnd = tomorrowStart.addingTimeInterval(86_400)

        let taskDescriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                !task.isCompleted &&
                task.dueDate != nil &&
                task.dueDate! >= tomorrowStart &&
                task.dueDate! < tomorrowEnd
            }
        )
        let dueTomorrow = (try? context.fetch(taskDescriptor)) ?? []

        let segmentDescriptor = FetchDescriptor<ItinerarySegment>(
            predicate: #Predicate { segment in
                segment.startDate >= tomorrowStart && segment.startDate < tomorrowEnd
            },
            sortBy: [SortDescriptor(\.startDate)]
        )
        let nextSegment = (try? context.fetch(segmentDescriptor))?.first

        return TomorrowAgendaEntry(
            date: .now,
            taskCount: dueTomorrow.count,
            nextHeadline: nextSegment?.title
        )
    }
}

struct TomorrowAgendaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TomorrowAgendaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tomorrow").font(.caption.weight(.semibold))
            Text("\(entry.taskCount) shared task\(entry.taskCount == 1 ? "" : "s")")
                .font(.caption2)
            if let headline = entry.nextHeadline {
                Text(headline)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

struct TomorrowAgendaWidget: Widget {
    let kind = "TomorrowAgendaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TomorrowAgendaProvider()) { entry in
            TomorrowAgendaWidgetView(entry: entry)
        }
        .configurationDisplayName("Tomorrow's Agenda")
        .description("Shows on the Lock Screen and StandBy.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
    }
}
