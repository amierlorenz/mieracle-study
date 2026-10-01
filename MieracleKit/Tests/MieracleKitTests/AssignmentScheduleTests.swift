import Foundation
import MieracleKit
import Testing

struct AssignmentScheduleTests {
    let calendar = SM2SchedulerTests.calendar
    let now = SM2SchedulerTests.now
    var schedule: AssignmentSchedule { AssignmentSchedule(calendar: calendar) }

    func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!
    }

    func item(_ name: String, due: Int?, unlock: Int? = nil, kind: CanvasItemKind = .assignment) -> CanvasItem {
        let item = CanvasItem(canvasID: name, canvasCourseID: 1, name: name, kind: kind, dueAt: due.map { day($0).addingTimeInterval(23 * 3600) })
        item.unlockAt = unlock.map(day)
        return item
    }

    @Test(arguments: [
        (30, nil, 16),
        (10, nil, 0),
        (30, 20, 20),
        (5, -3, 0),
    ] as [(Int, Int?, Int)])
    func surfacesAtLatestOfLeadOpenAndToday(due: Int, unlock: Int?, expected: Int) {
        let date = schedule.surfaceDate(due: day(due), unlock: unlock.map(day), now: now)
        #expect(date == day(expected))
    }

    @Test func todayHasOpenWorkDueWithinTwoWeeks() {
        let soon = item("Lab 3", due: 5)
        let edge = item("Essay", due: 14)
        let later = item("Project", due: 30)
        let locked = item("Quiz prep", due: 10, unlock: 4)
        let submitted = item("HW 1", due: 2)
        submitted.isSubmitted = true
        let done = item("Reading", due: 3)
        done.isMarkedDone = true
        let past = item("HW 0", due: -1)
        let event = item("Office hours", due: 1, kind: .event)

        let all = [later, soon, edge, locked, submitted, done, past, event]
        #expect(schedule.today(all, now: now).map(\.name) == ["Lab 3", "Essay"])
        #expect(schedule.open(all, now: now).map(\.name) == ["Lab 3", "Quiz prep", "Essay", "Project"])
    }
}
