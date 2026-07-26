import Foundation
import SwiftData

/// A single to-do. Assignment is a swipe-cycled optional relationship rather
/// than a status flag: `nil` == Unassigned, otherwise the relationship points
/// at whichever `HouseholdMember` owns it. The "Unassigned -> Me -> Partner ->
/// Unassigned" swipe cycle used by `TaskListView` just walks that three-state
/// sequence and writes `assignee` directly.
@Model
public final class TaskItem {
    public var id: UUID = UUID()
    public var title: String = ""
    public var notes: String?
    public var isCompleted: Bool = false
    public var completedAt: Date?
    public var createdAt: Date = Date.now
    public var dueDate: Date?
    public var priority: TaskPriority = TaskPriority.normal

    /// Populated when the task originated from a Drop Zone link.
    public var sourceURL: String?

    public var household: Household?
    public var assignee: HouseholdMember?
    public var category: Category?
    public var locationReminder: LocationReminder?

    public init(
        title: String = "",
        notes: String? = nil,
        dueDate: Date? = nil,
        priority: TaskPriority = .normal,
        sourceURL: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.isCompleted = false
        self.completedAt = nil
        self.createdAt = .now
        self.dueDate = dueDate
        self.priority = priority
        self.sourceURL = sourceURL
    }

    /// Cycles Unassigned -> Me -> Partner -> Unassigned given the household roster.
    /// `currentMember` is the `HouseholdMember` that corresponds to the device's
    /// own iCloud account (see `HouseholdMember+CurrentUser` in the app target).
    public func cycleAssignment(currentMember: HouseholdMember?, partner: HouseholdMember?) {
        switch assignee?.id {
        case .none:
            assignee = currentMember
        case currentMember?.id:
            assignee = partner
        default:
            assignee = nil
        }
    }

    public func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? .now : nil
    }
}
