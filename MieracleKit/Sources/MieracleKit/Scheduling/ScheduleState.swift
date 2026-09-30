import Foundation

/// A value snapshot of a concept's review schedule.
public struct ScheduleState: Equatable, Sendable {
    public var ease: Double
    public var intervalDays: Double
    public var repetitions: Int
    public var lapses: Int
    public var dueDate: Date?
    public var lastReviewedAt: Date?

    public init(ease: Double = 2.5, intervalDays: Double = 0, repetitions: Int = 0, lapses: Int = 0, dueDate: Date? = nil, lastReviewedAt: Date? = nil) {
        self.ease = ease
        self.intervalDays = intervalDays
        self.repetitions = repetitions
        self.lapses = lapses
        self.dueDate = dueDate
        self.lastReviewedAt = lastReviewedAt
    }
}

extension Concept {
    public var scheduleState: ScheduleState {
        get {
            ScheduleState(ease: ease, intervalDays: intervalDays, repetitions: repetitions, lapses: lapses, dueDate: dueDate, lastReviewedAt: lastReviewedAt)
        }
        set {
            ease = newValue.ease
            intervalDays = newValue.intervalDays
            repetitions = newValue.repetitions
            lapses = newValue.lapses
            dueDate = newValue.dueDate
            lastReviewedAt = newValue.lastReviewedAt
        }
    }

    /// Whether the concept has been studied and its due date has arrived.
    public func isDue(at now: Date) -> Bool {
        guard !isNew, let dueDate else { return false }
        return dueDate <= now
    }
}
