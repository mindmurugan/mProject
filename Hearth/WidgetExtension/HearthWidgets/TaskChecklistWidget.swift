import WidgetKit
import SwiftUI
import SwiftData
import HearthKit

struct TaskChecklistEntry: TimelineEntry {
    let date: Date
    let tasks: [TaskItem]
}

struct TaskChecklistProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskChecklistEntry {
        TaskChecklistEntry(date: .now, tasks: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskChecklistEntry) -> Void) {
        completion(TaskChecklistEntry(date: .now, tasks: fetchTasks()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskChecklistEntry>) -> Void) {
        let entry = TaskChecklistEntry(date: .now, tasks: fetchTasks())
        // Widgets don't observe the store; a short refresh interval plus the
        // `WidgetCenter.shared.reloadTimelines` call from `ToggleTaskCompletionIntent`
        // keeps this reasonably fresh without excessive background wakeups.
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func fetchTasks() -> [TaskItem] {
        guard let container = try? HearthSchema.makeContainer() else { return [] }
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 5
        return (try? context.fetch(descriptor)) ?? []
    }
}

struct TaskChecklistWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TaskChecklistEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tasks").font(.headline)
            if entry.tasks.isEmpty {
                Text("Nothing pending 🎉").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(entry.tasks.prefix(family == .systemSmall ? 3 : 5)) { task in
                    HStack {
                        Button(intent: ToggleTaskCompletionIntent(taskID: task.id.uuidString)) {
                            Image(systemName: "circle")
                        }
                        .buttonStyle(.plain)

                        Text(task.title)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

struct TaskChecklistWidget: Widget {
    let kind = "TaskChecklistWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskChecklistProvider()) { entry in
            TaskChecklistWidgetView(entry: entry)
        }
        .configurationDisplayName("Hearth Tasks")
        .description("Check off shared tasks without opening the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
