import Foundation
import SwiftData

/// Tracks the daily limit on introducing new concepts.
public enum NewConceptBudget {
    public static let defaultLimit = 15

    /// Concepts studied for the first time since the start of today.
    public static func introducedToday(in context: ModelContext, now: Date = .now, calendar: Calendar = .current) throws -> Int {
        let start = calendar.startOfDay(for: now)
        return try context.fetchCount(FetchDescriptor<ReviewLog>(predicate: #Predicate { $0.wasNew && $0.reviewedAt >= start }))
    }

    public static func remaining(limit: Int, in context: ModelContext, now: Date = .now, calendar: Calendar = .current) throws -> Int {
        max(0, limit - (try introducedToday(in: context, now: now, calendar: calendar)))
    }
}
