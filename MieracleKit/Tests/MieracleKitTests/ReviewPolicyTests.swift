import Foundation
import MieracleKit
import Testing

struct ReviewPolicyTests {
    let policy = ReviewPolicy(calendar: SM2SchedulerTests.calendar)
    let now = SM2SchedulerTests.now
    let mature = ScheduleState(intervalDays: 20, repetitions: 4, dueDate: .distantFuture)

    func days(_ n: Int) -> Date {
        SM2SchedulerTests.calendar.date(byAdding: .day, value: n, to: now)!
    }

    @Test(arguments: [Grade.hard, .good, .easy])
    func practicePassOnNotDueConceptKeepsSchedule(grade: Grade) {
        let next = policy.next(mature, grade: grade, context: .init(mode: .practice, isNew: false, wasDue: false, now: now))
        #expect(next == mature)
    }

    @Test func practiceFailurePullsDueDateIn() {
        let next = policy.next(mature, grade: .again, context: .init(mode: .practice, isNew: false, wasDue: false, now: now))
        #expect(next.intervalDays == 1)
        #expect(next.lapses == 1)
    }

    @Test func practiceOnNewConceptSchedulesIt() {
        let next = policy.next(.init(), grade: .good, context: .init(mode: .practice, isNew: true, wasDue: false, now: now))
        #expect(next.dueDate != nil)
    }

    @Test func practiceOnDueConceptSchedulesNormally() {
        let next = policy.next(mature, grade: .good, context: .init(mode: .practice, isNew: false, wasDue: true, now: now))
        #expect(next.intervalDays == 50)
    }

    @Test(arguments: [(10, 5.0), (7, 3.0), (3, 1.0), (1, 1.0), (200, 50.0)])
    func examCapsInterval(daysUntilExam: Int, expected: Double) {
        let next = policy.next(mature, grade: .good, context: .init(mode: .review, isNew: false, wasDue: true, examDates: [days(daysUntilExam)], now: now))
        #expect(next.intervalDays == expected)
        #expect(next.dueDate! <= days(daysUntilExam))
    }

    @Test func nearestExamWins() {
        let next = policy.next(mature, grade: .good, context: .init(mode: .review, isNew: false, wasDue: true, examDates: [days(30), days(8)], now: now))
        #expect(next.intervalDays == 4)
    }

    @Test func pastExamsAreIgnored() {
        let next = policy.next(mature, grade: .good, context: .init(mode: .review, isNew: false, wasDue: true, examDates: [days(-3), days(0)], now: now))
        #expect(next.intervalDays == 50)
    }
}
