import Foundation
import MieracleKit
import SwiftData
import Testing

@MainActor
struct ReviewRecorderTests {
    let container: ModelContainer
    let context: ModelContext
    let recorder: ReviewRecorder
    let now = SM2SchedulerTests.now

    init() throws {
        container = try ModelContainerFactory.make(storage: .inMemory)
        context = container.mainContext
        recorder = ReviewRecorder(context: context, policy: ReviewPolicy(calendar: SM2SchedulerTests.calendar))
        try Importer(context: context).apply(ImportDocument.decode(from: ImportDocumentTests.fixture()))
    }

    func prompt(_ id: String) throws -> Prompt {
        try #require(try context.fetch(FetchDescriptor<Prompt>(predicate: #Predicate { $0.externalID == id })).first)
    }

    @Test func firstReviewIntroducesConceptAndLogs() throws {
        let card = try prompt("cs201.heaps.top-k.pattern")
        let log = try recorder.record(.good, for: card, confidence: .sure, duration: 4, mode: .learnNew, now: now)

        let concept = try #require(card.concept)
        #expect(concept.introducedAt == now)
        #expect(concept.repetitions == 1)
        #expect(card.lastShownAt == now)
        #expect(log.wasNew)
        #expect(!log.wasDue)
        #expect(log.confidence == .sure)
        #expect(concept.reviews?.count == 1)
    }

    @Test func examCoveringConceptCapsInterval() throws {
        let card = try prompt("cs201.heaps.heap-property.fc")
        let concept = try #require(card.concept)
        concept.introducedAt = now.addingTimeInterval(-86_400 * 60)
        concept.scheduleState = .init(intervalDays: 30, repetitions: 5, dueDate: now)
        let exam = try #require(try context.fetch(FetchDescriptor<Exam>()).first)
        exam.date = SM2SchedulerTests.calendar.date(byAdding: .day, value: 6, to: now)!

        try recorder.record(.easy, for: card, duration: 2, mode: .review, now: now)

        #expect(concept.intervalDays == 3)
    }

    @Test func dailyBudgetCountsOnlyTodaysNewConcepts() throws {
        try recorder.record(.good, for: prompt("cs201.heaps.top-k.pattern"), duration: 1, mode: .learnNew, now: now)
        try recorder.record(.good, for: prompt("cs201.heaps.top-k.code"), duration: 1, mode: .practice, now: now)
        let yesterday = now.addingTimeInterval(-86_400)
        try recorder.record(.good, for: prompt("cs201.heaps.heap-property.fc"), duration: 1, mode: .learnNew, now: yesterday)

        let calendar = SM2SchedulerTests.calendar
        #expect(try NewConceptBudget.introducedToday(in: context, now: now, calendar: calendar) == 1)
        #expect(try NewConceptBudget.remaining(limit: 15, in: context, now: now, calendar: calendar) == 14)
        #expect(try NewConceptBudget.remaining(limit: 1, in: context, now: now, calendar: calendar) == 0)
    }
}
