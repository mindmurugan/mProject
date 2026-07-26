import AppIntents
import SwiftData
import HearthKit

/// Backs the checkbox button in `TaskChecklistWidget`. Runs in the widget
/// extension process, opens the same App Group-backed store the app and
/// share extension use, and flips completion in place -- no need to launch
/// the app.
struct ToggleTaskCompletionIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task"
    static var description = IntentDescription("Marks a Hearth task complete or incomplete.")

    @Parameter(title: "Task ID")
    var taskIDString: String

    init() {}

    init(taskID: String) {
        self.taskIDString = taskID
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: taskIDString) else { return .result() }

        let container = try HearthSchema.makeContainer()
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.id == uuid })
        if let task = try context.fetch(descriptor).first {
            task.toggleCompletion()
            try context.save()
        }

        return .result()
    }
}
