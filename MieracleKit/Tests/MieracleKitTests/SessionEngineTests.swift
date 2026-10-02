import Foundation
import MieracleKit
import SwiftData
import Testing

@MainActor
struct SessionEngineTests {
    let container: ModelContainer
    let context: ModelContext
    let now = SM2SchedulerTests.now
    let policy = ReviewPolicy(calendar: SM2SchedulerTests.calendar)

    init() throws {
        container = try ModelContainerFactory.make(storage: .inMemory)
        context = container.mainContext
        try Importer(context: context).apply(ImportDocument.decode(from: ImportDocumentTests.fixture()))
    }

    func engine(_ config: SessionConfig, limit: Int = 15, code: Bool = true) throws -> SessionEngine {
        try SessionEngine(config: config, context: context, dailyNewLimit: limit, supportsCodeExecution: code, policy: policy, now: now)
    }

    @Test func learnNewServesEveryNewConceptAndIntroducesThem() throws {
        let session = try engine(.init(mode: .learnNew))
        #expect(session.queue.count == 2)
        while let _ = session.currentItem {
            try session.answer(.good, duration: 2, now: now)
        }
        #expect(session.isFinished)
        #expect(try context.fetch(FetchDescriptor<Concept>()).allSatisfy { !$0.isNew })
        #expect(try context.fetchCount(FetchDescriptor<ReviewLog>()) == 2)
        let record = try #require(try context.fetch(FetchDescriptor<StudySession>()).first)
        #expect(record.endedAt == now)
    }

    @Test func respectsDailyNewLimit() throws {
        #expect(try engine(.init(mode: .learnNew), limit: 1).queue.count == 1)
    }

    @Test func againRequeuesOnceWithAnotherPrompt() throws {
        let session = try engine(.init(mode: .learnNew, length: .count(1)))
        let first = try #require(session.currentItem)
        try session.answer(.again, duration: 1, now: now)

        #expect(session.queue.count == 2)
        let retry = try #require(session.currentItem)
        #expect(retry.conceptID == first.conceptID)
        #expect(retry.promptID != first.promptID)

        try session.answer(.again, duration: 1, now: now)
        #expect(session.isFinished)
        #expect(session.summary.answered == 2)
        #expect(session.summary.needsWork == [first.conceptID])
    }

    @Test func summaryKeepsWorstGrade() throws {
        let session = try engine(.init(mode: .learnNew))
        try session.answer(.easy, duration: 1, now: now)
        try session.answer(.hard, duration: 1, now: now)
        #expect(session.summary.count(of: .easy) == 1)
        #expect(session.summary.count(of: .hard) == 1)
        #expect(session.summary.needsWork.count == 1)
    }

    @Test func emptyQueueStartsFinished() throws {
        #expect(try engine(.init(mode: .review)).isFinished)
    }

    @Test func timedSessionEndsWhenTimeRunsOut() throws {
        let session = try engine(.init(mode: .learnNew, length: .minutes(10)))
        #expect(session.timeRemaining(at: now) == 600)
        try session.answer(.good, duration: 700, now: now.addingTimeInterval(700))
        #expect(session.isFinished)
        #expect(session.remainingCount == 0)
    }

    @Test func conceptScopeTargetsSpecificConcepts() throws {
        let session = try engine(.init(scope: .init(conceptIDs: ["cs201.heaps.top-k"]), mode: .practice))
        #expect(session.queue.map(\.conceptID) == ["cs201.heaps.top-k"])
    }

    @Test func undoRestoresTheLastAnswerExactly() throws {
        let session = try engine(.init(mode: .learnNew, length: .count(1)))
        let item = try #require(session.currentItem)
        let concept = try #require(session.currentConcept)

        try session.answer(.again, duration: 2, now: now)
        #expect(session.queue.count == 2)
        #expect(session.canUndo)

        try session.undoLastAnswer()

        #expect(session.currentItem == item)
        #expect(session.position == 0)
        #expect(session.queue.count == 1)
        #expect(concept.isNew)
        #expect(concept.lapses == 0)
        #expect(session.summary.answered == 0)
        #expect(!session.canUndo)
        #expect(try context.fetchCount(FetchDescriptor<ReviewLog>()) == 0)
    }

    @Test func undoReopensAFinishedSession() throws {
        let session = try engine(.init(mode: .learnNew, length: .count(1)))
        try session.answer(.good, duration: 1, now: now)
        #expect(session.isFinished)

        try session.undoLastAnswer()

        #expect(!session.isFinished)
        #expect(session.remainingCount == 1)
        let record = try #require(try context.fetch(FetchDescriptor<StudySession>()).first)
        #expect(record.endedAt == nil)
    }
}
