import Foundation
import SwiftData

/// A single answer to a prompt. Logs are append-only and hold everything a
/// future scheduler (such as FSRS) needs to be fitted to real history.
@Model
public final class ReviewLog {
    public var reviewedAt: Date = Date.now
    public var gradeRaw: String = Grade.good.rawValue
    public var confidenceRaw: String?
    public var duration: TimeInterval = 0
    public var modeRaw: String = StudyMode.review.rawValue
    /// Whether the concept was due when answered.
    public var wasDue: Bool = true
    /// Whether this was the concept's first-ever review.
    public var wasNew: Bool = false
    public var sessionID: UUID?

    public var concept: Concept?
    public var prompt: Prompt?

    public init(
        reviewedAt: Date = .now,
        grade: Grade,
        confidence: Confidence? = nil,
        duration: TimeInterval,
        mode: StudyMode,
        wasDue: Bool,
        wasNew: Bool,
        sessionID: UUID? = nil
    ) {
        self.reviewedAt = reviewedAt
        self.gradeRaw = grade.rawValue
        self.confidenceRaw = confidence?.rawValue
        self.duration = duration
        self.modeRaw = mode.rawValue
        self.wasDue = wasDue
        self.wasNew = wasNew
        self.sessionID = sessionID
    }

    public var grade: Grade { Grade(rawValue: gradeRaw) ?? .good }
    public var confidence: Confidence? { confidenceRaw.flatMap(Confidence.init(rawValue:)) }
    public var mode: StudyMode { StudyMode(rawValue: modeRaw) ?? .review }
}
