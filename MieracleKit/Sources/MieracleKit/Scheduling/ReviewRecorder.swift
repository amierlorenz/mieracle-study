import Foundation
import SwiftData

/// Records an answer: logs it, reschedules the concept, and marks the prompt shown.
public struct ReviewRecorder {
    private let context: ModelContext
    private let policy: ReviewPolicy

    public init(context: ModelContext, policy: ReviewPolicy = ReviewPolicy()) {
        self.context = context
        self.policy = policy
    }

    @discardableResult
    public func record(
        _ grade: Grade,
        for prompt: Prompt,
        confidence: Confidence? = nil,
        duration: TimeInterval,
        mode: StudyMode,
        sessionID: UUID? = nil,
        now: Date = .now
    ) throws -> ReviewLog {
        guard let concept = prompt.concept else {
            throw RecorderError.promptHasNoConcept
        }
        let isNew = concept.isNew
        let wasDue = concept.isDue(at: now)
        let examDates = try upcomingExams(after: now).filter { $0.covers(concept) }.map(\.date)

        concept.scheduleState = policy.next(
            concept.scheduleState,
            grade: grade,
            context: .init(mode: mode, isNew: isNew, wasDue: wasDue, examDates: examDates, now: now)
        )
        if isNew {
            concept.introducedAt = now
        }
        prompt.lastShownAt = now

        let log = ReviewLog(reviewedAt: now, grade: grade, confidence: confidence, duration: duration, mode: mode, wasDue: wasDue, wasNew: isNew, sessionID: sessionID)
        context.insert(log)
        log.concept = concept
        log.prompt = prompt
        try context.save()
        return log
    }

    private func upcomingExams(after now: Date) throws -> [Exam] {
        try context.fetch(FetchDescriptor<Exam>(predicate: #Predicate { $0.date > now }))
    }

    public enum RecorderError: Error {
        case promptHasNoConcept
    }
}
