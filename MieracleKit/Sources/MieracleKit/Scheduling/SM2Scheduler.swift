import Foundation

/// Anki-flavored SM-2 with four grades and whole-day intervals.
///
/// | Grade | Ease | Interval |
/// |---|---|---|
/// | Again | −0.20 | 1 day; repetitions reset, lapse counted |
/// | Hard | −0.15 | previous × 1.2 |
/// | Good | — | 1 day, then 3 days, then previous × ease |
/// | Easy | +0.15 | 4 days, then previous × ease × 1.3 |
///
/// Ease never drops below ``minimumEase``.
public struct SM2Scheduler: Scheduler {
    public static let minimumEase = 1.3

    public init() {}

    public func schedule(_ state: ScheduleState, grade: Grade, now: Date, calendar: Calendar) -> ScheduleState {
        var next = state
        let previous = state.intervalDays
        let interval: Double

        switch grade {
        case .again:
            next.repetitions = 0
            next.lapses += 1
            next.ease -= 0.2
            interval = 1
        case .hard:
            next.repetitions += 1
            next.ease -= 0.15
            interval = previous * 1.2
        case .good:
            next.repetitions += 1
            interval = switch state.repetitions {
            case 0: 1
            case 1: 3
            default: previous * state.ease
            }
        case .easy:
            next.repetitions += 1
            next.ease += 0.15
            interval = state.repetitions == 0 ? 4 : previous * state.ease * 1.3
        }

        next.ease = max(Self.minimumEase, next.ease)
        next.intervalDays = max(1, interval.rounded())
        next.lastReviewedAt = now
        next.dueDate = dueDate(afterDays: next.intervalDays, from: now, calendar: calendar)
        return next
    }
}
