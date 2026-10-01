import Foundation
import MieracleKit
import SwiftData
import Testing

@MainActor
struct StudyOverviewTests {
    let container: ModelContainer
    let context: ModelContext
    let now = SM2SchedulerTests.now
    let calendar = SM2SchedulerTests.calendar

    init() throws {
        container = try ModelContainerFactory.make(storage: .inMemory)
        context = container.mainContext
        try Importer(context: context).apply(ImportDocument.decode(from: ImportDocumentTests.fixture()))
    }

    func concept(_ id: String) throws -> Concept {
        try #require(try context.fetch(FetchDescriptor<Concept>()).first { $0.externalID == id })
    }

    @Test func countsDueAndNewPerCourse() throws {
        let heap = try concept("cs201.heaps.heap-property")
        heap.introducedAt = now.addingTimeInterval(-86_400)
        heap.dueDate = now.addingTimeInterval(-60)

        let overview = StudyOverview(courses: try context.fetch(FetchDescriptor<Course>()), exams: [], now: now, calendar: calendar)

        let counts = try #require(overview.courses.first)
        #expect(counts.due == 1)
        #expect(counts.new == 1)
        #expect(counts.total == 2)
    }

    @Test func examReadinessCountsStudiedAndWeak() throws {
        let exam = try #require(try context.fetch(FetchDescriptor<Exam>()).first)
        exam.date = calendar.date(byAdding: .day, value: 5, to: now)!
        let heap = try concept("cs201.heaps.heap-property")
        heap.introducedAt = now
        heap.ease = 1.8

        let readiness = try #require(StudyOverview(courses: [], exams: [exam], now: now, calendar: calendar).exams.first)

        #expect(readiness.daysLeft == 5)
        #expect(readiness.conceptCount == 2)
        #expect(readiness.studied == 1)
        #expect(readiness.weak == 1)
        #expect(readiness.studiedFraction == 0.5)
        #expect(readiness.scope.unitIDs == ["cs201.heaps"])
    }

    @Test func pastExamsAreHidden() throws {
        let exam = try #require(try context.fetch(FetchDescriptor<Exam>()).first)
        exam.date = now.addingTimeInterval(-3 * 86_400)
        #expect(StudyOverview(courses: [], exams: [exam], now: now, calendar: calendar).exams.isEmpty)
    }
}
