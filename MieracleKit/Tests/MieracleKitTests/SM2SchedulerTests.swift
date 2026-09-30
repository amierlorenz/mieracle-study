import Foundation
import MieracleKit
import Testing

struct SM2SchedulerTests {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()
    static let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 15))!

    struct Case: Sendable, CustomTestStringConvertible {
        let state: ScheduleState
        let grade: Grade
        let interval: Double
        let ease: Double
        let repetitions: Int
        let lapses: Int
        var testDescription: String { "\(grade) at rep \(state.repetitions), interval \(state.intervalDays)" }
    }

    static let cases: [Case] = [
        Case(state: .init(), grade: .again, interval: 1, ease: 2.3, repetitions: 0, lapses: 1),
        Case(state: .init(), grade: .hard, interval: 1, ease: 2.35, repetitions: 1, lapses: 0),
        Case(state: .init(), grade: .good, interval: 1, ease: 2.5, repetitions: 1, lapses: 0),
        Case(state: .init(), grade: .easy, interval: 4, ease: 2.65, repetitions: 1, lapses: 0),
        Case(state: .init(intervalDays: 1, repetitions: 1), grade: .good, interval: 3, ease: 2.5, repetitions: 2, lapses: 0),
        Case(state: .init(intervalDays: 3, repetitions: 2), grade: .good, interval: 8, ease: 2.5, repetitions: 3, lapses: 0),
        Case(state: .init(intervalDays: 10, repetitions: 3), grade: .hard, interval: 12, ease: 2.35, repetitions: 4, lapses: 0),
        Case(state: .init(intervalDays: 10, repetitions: 3), grade: .easy, interval: 33, ease: 2.65, repetitions: 4, lapses: 0),
        Case(state: .init(intervalDays: 30, repetitions: 5, lapses: 2), grade: .again, interval: 1, ease: 2.3, repetitions: 0, lapses: 3),
        Case(state: .init(ease: 1.35, intervalDays: 5, repetitions: 3), grade: .again, interval: 1, ease: 1.3, repetitions: 0, lapses: 1),
    ]

    @Test(arguments: cases)
    func schedules(testCase: Case) {
        let next = SM2Scheduler().schedule(testCase.state, grade: testCase.grade, now: Self.now, calendar: Self.calendar)
        #expect(next.intervalDays == testCase.interval)
        #expect(abs(next.ease - testCase.ease) < 0.0001)
        #expect(next.repetitions == testCase.repetitions)
        #expect(next.lapses == testCase.lapses)
        #expect(next.lastReviewedAt == Self.now)
    }

    @Test func dueAtStartOfDayAfterInterval() {
        let next = SM2Scheduler().schedule(.init(intervalDays: 1, repetitions: 1), grade: .good, now: Self.now, calendar: Self.calendar)
        let expected = Self.calendar.date(from: DateComponents(year: 2026, month: 10, day: 4))
        #expect(next.dueDate == expected)
    }

    @Test func gradesOrderIntervals() {
        let state = ScheduleState(intervalDays: 6, repetitions: 3)
        let intervals = Grade.allCases.map { SM2Scheduler().schedule(state, grade: $0, now: Self.now, calendar: Self.calendar).intervalDays }
        #expect(intervals == intervals.sorted())
    }
}
