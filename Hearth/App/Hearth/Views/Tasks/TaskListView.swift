import SwiftUI
import SwiftData
import HearthKit

private enum TaskFilter: String, CaseIterable, Identifiable {
    case mine = "My Tasks"
    case shared = "Shared / Unassigned"
    case completed = "Completed Log"

    var id: String { rawValue }
}

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var currentMemberResolver: CurrentMemberResolver

    @Query(sort: \HouseholdMember.createdAt) private var members: [HouseholdMember]
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var filter: TaskFilter = .mine
    @State private var isPresentingQuickAdd = false

    private var me: HouseholdMember? { currentMemberResolver.currentMember(in: members) }
    private var partner: HouseholdMember? { currentMemberResolver.partner(in: members) }

    private var filteredTasks: [TaskItem] {
        switch filter {
        case .mine:
            return allTasks.filter { !$0.isCompleted && $0.assignee?.id == me?.id }
        case .shared:
            return allTasks.filter { !$0.isCompleted && ($0.assignee == nil || $0.assignee?.id == partner?.id) }
        case .completed:
            return allTasks.filter(\.isCompleted)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HearthBackground()

                VStack(spacing: 12) {
                    Picker("Filter", selection: $filter) {
                        ForEach(TaskFilter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    List {
                        ForEach(filteredTasks) { task in
                            TaskRowView(task: task, me: me, partner: partner)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        withAnimation { task.cycleAssignment(currentMember: me, partner: partner) }
                                    } label: {
                                        Label("Assign", systemImage: "person.crop.circle.badge.checkmark")
                                    }
                                    .tint(.indigo)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation { task.toggleCompletion() }
                                    } label: {
                                        Label(task.isCompleted ? "Reopen" : "Done", systemImage: task.isCompleted ? "arrow.uturn.left" : "checkmark")
                                    }
                                    .tint(task.isCompleted ? .gray : .green)
                                }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
                .navigationTitle("Tasks")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isPresentingQuickAdd = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
                .sheet(isPresented: $isPresentingQuickAdd) {
                    QuickAddTaskView()
                }
            }
        }
    }
}

#Preview {
    TaskListView()
        .environmentObject(CurrentMemberResolver())
        .modelContainer(for: HearthSchema.schema, inMemory: true)
}
