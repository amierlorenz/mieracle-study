import Foundation

/// Decides when Canvas assignments surface for work.
///
/// An assignment appears on the schedule on the latest of: two weeks before
/// it's due, the day it opens, and today. So work shows up early enough to
/// plan, but never before it can be started.
public struct AssignmentSchedule: Sendable {
    public static let leadDays = 14

    public var calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// The day an assignment first appears on the schedule.
    public func surfaceDate(due: Date, unlock: Date?, now: Date) -> Date {
        let today = calendar.startOfDay(for: now)
        let lead = calendar.date(byAdding: .day, value: -Self.leadDays, to: calendar.startOfDay(for: due)) ?? due
        let opens = unlock.map(calendar.startOfDay(for:)) ?? .distantPast
        return max(lead, opens, today)
    }

    /// Assignments still to do: not submitted, not marked done, and not past due.
    public func open(_ items: [CanvasItem], now: Date) -> [CanvasItem] {
        items.filter { item in
            item.kind == .assignment && !item.isExam && !item.isSubmitted && !item.isMarkedDone
                && (item.dueAt.map { $0 >= now } ?? true)
        }
        .sorted { ($0.dueAt ?? .distantFuture, $0.name) < ($1.dueAt ?? .distantFuture, $1.name) }
    }

    /// Open assignments that have surfaced by today.
    public func today(_ items: [CanvasItem], now: Date) -> [CanvasItem] {
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now
        return open(items, now: now).filter { item in
            guard let due = item.dueAt else { return false }
            return surfaceDate(due: due, unlock: item.unlockAt, now: now) < endOfToday
        }
    }
}
