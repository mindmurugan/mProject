import SwiftUI
import SwiftData
import HearthKit

/// Deliberately minimal: title + optional due date. Category and assignment
/// are meant to happen via triage/swipe, not a long add-task form.
struct QuickAddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var households: [Household]

    @State private var title = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date.now

    var body: some View {
        NavigationStack {
            Form {
                TextField("What needs doing?", text: $title)

                Toggle("Due date", isOn: $hasDueDate.animation())
                if hasDueDate {
                    DatePicker("Due", selection: $dueDate, displayedComponents: [.date])
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addTask() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addTask() {
        let task = TaskItem(title: title, dueDate: hasDueDate ? dueDate : nil)
        task.household = households.first
        modelContext.insert(task)
        dismiss()
    }
}

#Preview {
    QuickAddTaskView()
        .modelContainer(for: HearthSchema.schema, inMemory: true)
}
