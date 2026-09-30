import Foundation

/// Wraps a ``Scheduler`` with the app's study rules.
///
/// - **Practice mode:** passing a concept that isn't due leaves its schedule
///   alone, because early success mostly reflects short-term memory. Failing it
///   still reschedules, pulling the due date in.
/// - **Exam cap:** for concepts on an upcoming exam, the interval is at most
///   half the days remaining, so each concept comes up at least twice in the
///   final week and never after the exam.
public struct ReviewPolicy: Sendable {
    public var scheduler: any Scheduler
    public var calendar: Calendar

    public init(scheduler: any Scheduler = SM2Scheduler(), calendar: Calendar = .current) {
        self.scheduler = scheduler
        self.calendar = calendar
    }

    public struct Context: Sendable {
        public var mode: StudyMode
        public var isNew: Bool
        public var wasDue: Bool
        /// Dates of exams covering the concept; past dates are ignored.
        public var examDates: [Date]
        public var now: Date

        public init(mode: StudyMode, isNew: Bool, wasDue: Bool, examDates: [Date] = [], now: Date) {
            self.mode = mode
            self.isNew = isNew
            self.wasDue = wasDue
            self.examDates = examDates
            self.now = now
        }
    }

    public func next(_ state: ScheduleState, grade: Grade, context: Context) -> ScheduleState {
        if context.mode == .practice, !context.isNew, !context.wasDue, grade.isPass {
            return state
        }
        let next = scheduler.schedule(state, grade: grade, now: context.now, calendar: calendar)
        return capped(next, examDates: context.examDates, now: context.now)
    }

    func capped(_ state: ScheduleState, examDates: [Date], now: Date) -> ScheduleState {
        let today = calendar.startOfDay(for: now)
        let daysLeft = examDates
            .compactMap { calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: $0)).day }
            .filter { $0 > 0 }
            .min()
        guard let daysLeft else { return state }

        let cap = max(1, Double(daysLeft / 2))
        guard state.intervalDays > cap else { return state }
        var capped = state
        capped.intervalDays = cap
        capped.dueDate = calendar.date(byAdding: .day, value: Int(cap), to: today)
        return capped
    }
}
