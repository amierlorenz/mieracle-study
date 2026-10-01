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
        public var removedItems = 0
        /// Additions, removals, and date moves, for showing the user. The first
        /// sync of a course reports nothing, since everything would be "new".
        public var changes: [CanvasChange] = []
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
        let examItemIDs = Set(try context.fetch(FetchDescriptor<Exam>()).compactMap(\.canvasItemID))
        let previouslySynced = Set(items.values.map(\.canvasCourseID))
        var result = Result()
        func change(_ kind: CanvasChange.Kind, id: String, course: Int, name: String, old: Date?, new: Date?) {
            result.changes.append(CanvasChange(kind: kind, canvasID: id, canvasCourseID: course, name: name, oldDate: old, newDate: new, isExam: examItemIDs.contains(id), detectedAt: now))
        }
        for entry in fetched {
            if let item = items[entry.id] {
                if item.dueAt != entry.due {
                    change(.rescheduled, id: entry.id, course: entry.course, name: entry.name, old: item.dueAt, new: entry.due)
                }
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
                if previouslySynced.contains(entry.course) {
                    change(.added, id: entry.id, course: entry.course, name: entry.name, old: nil, new: entry.due)
                }
            }
        }

        let fetchedIDs = Set(fetched.map(\.id))
        for item in items.values where courseIDs.contains(item.canvasCourseID) && !fetchedIDs.contains(item.canvasID) {
            change(.removed, id: item.canvasID, course: item.canvasCourseID, name: item.name, old: item.dueAt, new: nil)
            items[item.canvasID] = nil
            context.delete(item)
            result.removedItems += 1
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
    ///
    /// Words like "final" and "test" also appear in projects and labs
    /// ("Final Project – Video Demo", "Lab 3 – Pen Test Execution"), so names
    /// that also mention a deliverable are excluded.
    public var looksLikeExam: Bool {
        let lowered = name.lowercased()
        guard lowered.contains(/\b(exam|midterm|final|quiz|test)\b/) else { return false }
        return !lowered.contains(/\b(project|presentation|submission|report|proposal|peer|evaluation|demo|update|lab|homework|assignment|analysis|pen test|penetration)\b/)
    }
}
