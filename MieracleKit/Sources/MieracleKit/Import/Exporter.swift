import Foundation
import SwiftData

/// Writes the whole store as an ``ImportDocument`` for backups and round trips.
///
/// AI variants and review history are not exported; variants are regenerated
/// and history stays in iCloud.
public struct Exporter {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func document() throws -> ImportDocument {
        let courses = try context.fetch(FetchDescriptor<Course>(sortBy: [SortDescriptor(\.name)]))
        let exams = try context.fetch(FetchDescriptor<Exam>(sortBy: [SortDescriptor(\.date)]))
        return ImportDocument(
            courses: courses.map(Self.export),
            exams: exams.compactMap(Self.export)
        )
    }

    private static func export(_ course: Course) -> ImportDocument.Course {
        .init(id: course.externalID, name: course.name, shortName: course.shortName, coding: course.allowsCodingPrompts ? true : nil, units: course.sortedUnits.map(export))
    }

    private static func export(_ unit: CourseUnit) -> ImportDocument.Unit {
        let concepts = (unit.concepts ?? []).sorted { ($0.createdAt, $0.externalID) < ($1.createdAt, $1.externalID) }
        return .init(id: unit.externalID, name: unit.name, order: unit.sortIndex, concepts: concepts.map(export))
    }

    private static func export(_ concept: Concept) -> ImportDocument.Concept {
        let prompts = (concept.prompts ?? [])
            .filter { $0.origin != .aiVariant }
            .sorted { ($0.createdAt, $0.externalID) < ($1.createdAt, $1.externalID) }
            .compactMap { prompt in prompt.content.map { ImportDocument.Prompt(id: prompt.externalID, content: $0) } }
        return .init(
            id: concept.externalID,
            title: concept.title,
            explanation: concept.explanation,
            tags: (concept.tags ?? []).map(\.name).sorted(),
            resources: concept.resources,
            prompts: prompts
        )
    }

    private static func export(_ exam: Exam) -> ImportDocument.Exam? {
        guard let course = exam.course else { return nil }
        return .init(
            id: exam.externalID,
            courseId: course.externalID,
            name: exam.name,
            date: ImportDocument.Exam.format(exam.date),
            unitIds: (exam.units ?? []).map(\.externalID).sorted(),
            tags: (exam.tags ?? []).map(\.name).sorted()
        )
    }
}
