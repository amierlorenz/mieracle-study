import Foundation
import Observation
import SwiftData

/// Runs a study session: serves prompts in order, records answers, and
/// re-asks failed concepts once later in the session.
@MainActor
@Observable
public final class SessionEngine {
    /// How many items later a failed concept comes back.
    public static let requeueGap = 4

    public let sessionID = UUID()
    public let config: SessionConfig
    public let startedAt: Date
    public private(set) var queue: [SessionItem]
    public private(set) var position = 0
    public private(set) var summary = SessionSummary()
    public private(set) var isFinished = false

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let recorder: ReviewRecorder
    @ObservationIgnored private let builder: SessionBuilder
    @ObservationIgnored private let record: StudySession
    @ObservationIgnored private var concepts: [String: Concept]
    @ObservationIgnored private var prompts: [String: Prompt]
    @ObservationIgnored private var requeued: Set<String> = []

    /// Builds the queue from the store and starts a session.
    public init(
        config: SessionConfig,
        context: ModelContext,
        dailyNewLimit: Int,
        supportsCodeExecution: Bool,
        policy: ReviewPolicy = ReviewPolicy(),
        now: Date = .now
    ) throws {
        var rng = SystemRandomNumberGenerator()
        let allConcepts = try context.fetch(FetchDescriptor<Concept>())
        let newRemaining = try NewConceptBudget.remaining(limit: dailyNewLimit, in: context, now: now, calendar: policy.calendar)
        let builder = SessionBuilder(config: config, newRemaining: newRemaining, supportsCodeExecution: supportsCodeExecution)

        self.config = config
        self.context = context
        self.startedAt = now
        self.builder = builder
        self.recorder = ReviewRecorder(context: context, policy: policy)
        self.concepts = Dictionary(allConcepts.map { ($0.externalID, $0) }, uniquingKeysWith: { first, _ in first })
        self.prompts = Dictionary(allConcepts.flatMap { $0.prompts ?? [] }.map { ($0.externalID, $0) }, uniquingKeysWith: { first, _ in first })
        self.queue = builder.build(from: allConcepts.map(ConceptSnapshot.init), now: now, using: &rng)
        self.record = StudySession(sessionID: sessionID, startedAt: now, configData: config.encoded())
        context.insert(record)
        try context.save()
        isFinished = queue.isEmpty
    }

    public var currentItem: SessionItem? {
        isFinished ? nil : queue[safe: position]
    }

    public var currentPrompt: Prompt? {
        currentItem.flatMap { prompts[$0.promptID] }
    }

    public var currentConcept: Concept? {
        currentItem.flatMap { concepts[$0.conceptID] }
    }

    public var remainingCount: Int {
        isFinished ? 0 : queue.count - position
    }

    public func concept(withID id: String) -> Concept? {
        concepts[id]
    }

    /// Seconds left in a timed session, or `nil` if it isn't timed.
    public func timeRemaining(at now: Date = .now) -> TimeInterval? {
        guard case .minutes(let minutes) = config.length else { return nil }
        return max(0, startedAt.addingTimeInterval(TimeInterval(minutes * 60)).timeIntervalSince(now))
    }

    public func answer(_ grade: Grade, confidence: Confidence? = nil, duration: TimeInterval, now: Date = .now) throws {
        guard let item = currentItem, let prompt = prompts[item.promptID] else { return }
        try recorder.record(grade, for: prompt, confidence: confidence, duration: duration, mode: config.mode, sessionID: sessionID, now: now)
        summary.record(grade, for: item.conceptID)
        if grade == .again, !requeued.contains(item.conceptID) {
            requeued.insert(item.conceptID)
            let retry = SessionItem(conceptID: item.conceptID, promptID: retryPromptID(for: item), unitID: item.unitID)
            queue.insert(retry, at: min(position + 1 + Self.requeueGap, queue.count))
        }
        position += 1
        if position >= queue.count || timeRemaining(at: now) == 0 {
            try finish(at: now)
        }
    }

    /// Ends the session early or after the last item.
    public func finish(at now: Date = .now) throws {
        guard record.endedAt == nil else { return }
        isFinished = true
        record.endedAt = now
        try context.save()
    }

    private func retryPromptID(for item: SessionItem) -> String {
        guard let concept = concepts[item.conceptID] else { return item.promptID }
        let others = builder.eligiblePrompts(of: ConceptSnapshot(concept)).filter { $0.id != item.promptID }
        return others.randomElement()?.id ?? item.promptID
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
