import Foundation

/// Computes a concept's next schedule from a grade.
///
/// Conformances implement a spaced-repetition algorithm; the rules layered on
/// top (practice mode, exam caps) live in ``ReviewPolicy``.
public protocol Scheduler: Sendable {
    func schedule(_ state: ScheduleState, grade: Grade, now: Date, calendar: Calendar) -> ScheduleState
}

extension Scheduler {
    /// The start of the day `days` after `now`, which is when a concept becomes due.
    func dueDate(afterDays days: Double, from now: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: Int(days), to: start) ?? start
    }
}
