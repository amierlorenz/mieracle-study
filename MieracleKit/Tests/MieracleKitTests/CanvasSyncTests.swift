import Foundation
import MieracleKit
import SwiftData
import Testing

@MainActor
struct CanvasSyncTests {
    let container: ModelContainer
    let context: ModelContext
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    init() throws {
        container = try ModelContainerFactory.make(storage: .inMemory)
        context = container.mainContext
        let course = Course(name: "CS 201")
        course.canvasCourseID = 7
        context.insert(course)
        try context.save()
    }

    func client(midtermDue: String) -> CanvasClient {
        let stub = StubURLProtocol.stub([
            "/api/v1/courses/7/assignments": .init(body: """
            [{"id": 1, "name": "Midterm 1", "due_at": "\(midtermDue)", "unlock_at": "2026-10-01T05:00:00Z"}, {"id": 2, "name": "Lab 3", "due_at": null}]
            """),
            "/api/v1/calendar_events": .init(body: #"[{"id": 9, "title": "Final Exam", "start_at": "2026-12-12T14:00:00Z"}]"#),
        ])
        return CanvasClient(baseURL: URL(string: "https://school.instructure.com")!, token: "fake", session: stub.session)
    }

    @Test func importsItemsAndSuggestsExams() async throws {
        let result = try await CanvasSync(context: context, client: client(midtermDue: "2026-10-20T15:00:00Z")).run(now: now)
        #expect(result.newItems == 3)
        let items = try context.fetch(FetchDescriptor<CanvasItem>(sortBy: [SortDescriptor(\.canvasID)]))
        #expect(items.map(\.canvasID) == ["assignment_1", "assignment_2", "event_9"])
        #expect(items.map(\.looksLikeExam) == [true, false, true])
        #expect(items[0].unlockAt == ISO8601DateFormatter().date(from: "2026-10-01T05:00:00Z"))
    }

    @Test func movedDatesUpdateLinkedExamsAndKeepMappings() async throws {
        try await CanvasSync(context: context, client: client(midtermDue: "2026-10-20T15:00:00Z")).run(now: now)
        let item = try #require(try context.fetch(FetchDescriptor<CanvasItem>()).first { $0.canvasID == "assignment_1" })
        let exam = try CanvasSync.makeExam(from: item, in: context)
        let unit = CourseUnit(name: "Heaps")
        unit.course = exam.course
        exam.units = [unit]
        #expect(exam.course?.name == "CS 201")
        #expect(item.isExam)

        let result = try await CanvasSync(context: context, client: client(midtermDue: "2026-10-27T15:00:00Z")).run(now: now)

        #expect(result.updatedItems == 1)
        #expect(result.movedExams == 1)
        #expect(exam.date == ISO8601DateFormatter().date(from: "2026-10-27T15:00:00Z"))
        #expect(exam.units?.first?.name == "Heaps")
        #expect(try context.fetchCount(FetchDescriptor<CanvasItem>()) == 3)
    }

    @Test func importsUnlinkedCoursesOnceAndKeepsAliases() throws {
        let canvasCourses = [CanvasCourse(id: 7, name: "Data Structures"), CanvasCourse(id: 8, name: "Linear Algebra")]
        #expect(try CanvasSync.importCourses(canvasCourses, into: context) == 1)

        let algebra = try #require(try context.fetch(FetchDescriptor<Course>()).first { $0.canvasCourseID == 8 })
        #expect(algebra.externalID == "canvas-8")
        algebra.name = "Lin Alg"
        #expect(try CanvasSync.importCourses(canvasCourses, into: context) == 0)
        #expect(algebra.name == "Lin Alg")
    }

    @Test(arguments: [(nil, true), (-3600.0, false), (-90_000.0, true)] as [(Double?, Bool)])
    func syncsAtMostDaily(offset: Double?, expected: Bool) {
        #expect(CanvasSync.isDue(lastSync: offset.map { now.addingTimeInterval($0) }, now: now) == expected)
    }

    @Test(arguments: [("Midterm 2", true), ("Final Exam", true), ("Quiz 4", true), ("Testing lab", false), ("Homework 3", false)])
    func examHeuristic(name: String, expected: Bool) {
        #expect(CanvasItem(canvasID: "x", canvasCourseID: 1, name: name, kind: .assignment, dueAt: nil).looksLikeExam == expected)
    }
}
