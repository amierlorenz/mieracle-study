import Foundation
import SwiftData

/// Pulls assignments and events for linked courses into ``CanvasItem``s and
/// keeps exam dates in step with Canvas.
///
/// Instructors move dates often, so linked exams take Canvas's date on every
/// sync; the user's unit and tag mappings are never touched.
@MainActor
public struct CanvasSync {
    public static let interval: TimeInterval = 24 * 60 * 60

    public struct Result: Equatable, Sendable {
        public var newItems = 0
        public var updatedItems = 0
        public var movedExams = 0
    }

    private let context: ModelContext
    private let client: CanvasClient

    public init(context: ModelContext, client: CanvasClient) {
        self.context = context
        self.client = client
    }

    public static func isDue(lastSync: Date?, now: Date = .now) -> Bool {
        guard let lastSync else { return true }
        return now.timeIntervalSince(lastSync) >= interval
    }

    @discardableResult
    public func run(now: Date = .now) async throws -> Result {
        let courseIDs = Set(try context.fetch(FetchDescriptor<Course>()).compactMap(\.canvasCourseID))
        var fetched: [(id: String, course: Int, name: String, kind: CanvasItemKind, due: Date?, unlock: Date?, submitted: Bool)] = []
        for courseID in courseIDs.sorted() {
            async let assignments = client.assignments(courseID: courseID)
            async let events = client.events(courseID: courseID)
            fetched += try await assignments.map { ("assignment_\($0.id)", courseID, $0.name, .assignment, $0.dueAt, $0.unlockAt, $0.isSubmitted) }
            fetched += try await events.map { ("event_\($0.id)", courseID, $0.title, .event, $0.startAt, nil, false) }
        }

        var items = Dictionary(try context.fetch(FetchDescriptor<CanvasItem>()).map { ($0.canvasID, $0) }, uniquingKeysWith: { first, _ in first })
        var result = Result()
        for entry in fetched {
            if let item = items[entry.id] {
                if item.name != entry.name || item.dueAt != entry.due || item.unlockAt != entry.unlock || item.isSubmitted != entry.submitted {
                    result.updatedItems += 1
                    item.name = entry.name
                    item.dueAt = entry.due
                    item.unlockAt = entry.unlock
                    item.isSubmitted = entry.submitted
                }
                item.lastSyncedAt = now
            } else {
                let item = CanvasItem(canvasID: entry.id, canvasCourseID: entry.course, name: entry.name, kind: entry.kind, dueAt: entry.due)
                item.unlockAt = entry.unlock
                item.isSubmitted = entry.submitted
                item.lastSyncedAt = now
                context.insert(item)
                items[entry.id] = item
                result.newItems += 1
            }
        }

        for exam in try context.fetch(FetchDescriptor<Exam>()) {
            guard let id = exam.canvasItemID, let due = items[id]?.dueAt, due != exam.date else { continue }
            exam.date = due
            result.movedExams += 1
        }
        try context.save()
        return result
    }

    /// Adds a class for each Canvas course not linked yet. Classes can be
    /// renamed freely afterwards; the link is the stored Canvas course id.
    @discardableResult
    public static func importCourses(_ courses: [CanvasCourse], into context: ModelContext) throws -> Int {
        let linked = Set(try context.fetch(FetchDescriptor<Course>()).compactMap(\.canvasCourseID))
        var added = 0
        for canvasCourse in courses where !linked.contains(canvasCourse.id) {
            let course = Course(externalID: "canvas-\(canvasCourse.id)", name: canvasCourse.name)
            course.canvasCourseID = canvasCourse.id
            context.insert(course)
            added += 1
        }
        try context.save()
        return added
    }

    /// Creates an exam from a Canvas item in the matching linked course.
    @discardableResult
    public static func makeExam(from item: CanvasItem, in context: ModelContext, now: Date = .now) throws -> Exam {
        let courseID = item.canvasCourseID
        let course = try context.fetch(FetchDescriptor<Course>(predicate: #Predicate { $0.canvasCourseID == courseID })).first
        let exam = Exam(name: item.name, date: item.dueAt ?? now)
        context.insert(exam)
        exam.course = course
        exam.canvasItemID = item.canvasID
        item.isExam = true
        try context.save()
        return exam
    }
}

extension CanvasItem {
    /// Whether the name suggests a graded test worth tracking as an exam.
    public var looksLikeExam: Bool {
        name.lowercased().contains(/\b(exam|midterm|final|quiz|test)\b/)
    }
}
