import Testing
@testable import HearthKit

@Suite("TaskItem assignment cycling")
struct TaskItemTests {
    @Test("Cycles Unassigned -> Me -> Partner -> Unassigned")
    func cycleAssignment() {
        let me = HouseholdMember(name: "Me")
        let partner = HouseholdMember(name: "Saral")
        let task = TaskItem(title: "Pick up paint swatches")

        #expect(task.assignee == nil)

        task.cycleAssignment(currentMember: me, partner: partner)
        #expect(task.assignee === me)

        task.cycleAssignment(currentMember: me, partner: partner)
        #expect(task.assignee === partner)

        task.cycleAssignment(currentMember: me, partner: partner)
        #expect(task.assignee == nil)
    }

    @Test("Toggling completion stamps completedAt")
    func toggleCompletion() {
        let task = TaskItem(title: "Book dinner reservation")
        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)

        task.toggleCompletion()
        #expect(task.isCompleted == true)
        #expect(task.completedAt != nil)

        task.toggleCompletion()
        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
    }
}
