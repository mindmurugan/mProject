import SwiftUI
import HearthKit

struct TaskRowView: View {
    let task: TaskItem
    let me: HouseholdMember?
    let partner: HouseholdMember?

    private var assignmentLabel: String {
        switch task.assignee?.id {
        case .none: return "Unassigned"
        case me?.id: return "Me"
        default: return task.assignee?.name ?? "Unassigned"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation { task.toggleCompletion() }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                if let category = task.category {
                    Label(category.name, systemImage: category.systemIconName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(spacing: 2) {
                MemberBadge(member: task.assignee)
                Text(assignmentLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .glassSurface(cornerRadius: 16)
    }
}
