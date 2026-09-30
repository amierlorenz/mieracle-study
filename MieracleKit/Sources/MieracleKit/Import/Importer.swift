import Foundation
import SwiftData

/// Upserts an ``ImportDocument`` into the store by stable id.
///
/// Imports never delete content and never touch a concept's schedule or review
/// history. The one exception: AI variants of a prompt whose content changed are
/// removed, because they copied the old answer.
public struct Importer {
    public enum Failure: Error, Equatable {
        case invalidDocument([ImportIssue])
    }

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Reports what ``apply(_:)`` would do without changing anything.
    public func plan(_ document: ImportDocument) throws -> ImportPlan {
        try run(document, dryRun: true)
    }

    /// Applies the document and saves. Throws ``Failure/invalidDocument(_:)`` if validation finds errors.
    @discardableResult
    public func apply(_ document: ImportDocument) throws -> ImportPlan {
        let plan = try run(document, dryRun: true)
        guard plan.canApply else { throw Failure.invalidDocument(plan.issues) }
        let applied = try run(document, dryRun: false)
        try context.save()
        return applied
    }

    private func run(_ document: ImportDocument, dryRun: Bool) throws -> ImportPlan {
        var store = try Store(context: context)
        var plan = ImportPlan()
        plan.issues = ImportValidator(
            knownCourseIDs: Set(store.courses.keys),
            knownUnitIDs: Set(store.units.keys)
        ).validate(document)
        guard dryRun || plan.canApply else { return plan }

        for course in document.courses {
            let model = upsertCourse(course, store: &store, counts: &plan.courses, dryRun: dryRun)
            for (index, unit) in course.units.enumerated() {
                let unitModel = upsertUnit(unit, index: index, courseID: course.id, parent: model, store: &store, counts: &plan.units, dryRun: dryRun)
                for concept in unit.concepts {
                    let conceptModel = try upsertConcept(concept, unitID: unit.id, parent: unitModel, store: &store, counts: &plan.concepts, dryRun: dryRun)
                    for prompt in concept.prompts {
                        upsertPrompt(prompt, conceptID: concept.id, parent: conceptModel, store: &store, counts: &plan.prompts, dryRun: dryRun)
                    }
                }
            }
        }
        for exam in document.exams {
            try upsertExam(exam, store: &store, counts: &plan.exams, dryRun: dryRun)
        }
        return plan
    }

    private func upsertCourse(_ item: ImportDocument.Course, store: inout Store, counts: inout ImportPlan.Counts, dryRun: Bool) -> Course? {
        guard let existing = store.courses[item.id] else {
            counts.new += 1
            guard !dryRun else { return nil }
            let course = Course(externalID: item.id, name: item.name)
            context.insert(course)
            store.courses[item.id] = course
            return course
        }
        if existing.name != item.name {
            counts.updated += 1
            if !dryRun { existing.name = item.name }
        } else {
            counts.unchanged += 1
        }
        return existing
    }

    private func upsertUnit(
        _ item: ImportDocument.Unit,
        index: Int,
        courseID: String,
        parent: Course?,
        store: inout Store,
        counts: inout ImportPlan.Counts,
        dryRun: Bool
    ) -> CourseUnit? {
        let sortIndex = item.order ?? index + 1
        guard let existing = store.units[item.id] else {
            counts.new += 1
            guard !dryRun else { return nil }
            let unit = CourseUnit(externalID: item.id, name: item.name, sortIndex: sortIndex)
            context.insert(unit)
            unit.course = parent
            store.units[item.id] = unit
            return unit
        }
        let changed = existing.name != item.name || existing.sortIndex != sortIndex || existing.course?.externalID != courseID
        counts.record(changed)
        if changed && !dryRun {
            existing.name = item.name
            existing.sortIndex = sortIndex
            existing.course = parent
        }
        return existing
    }

    private func upsertConcept(
        _ item: ImportDocument.Concept,
        unitID: String,
        parent: CourseUnit?,
        store: inout Store,
        counts: inout ImportPlan.Counts,
        dryRun: Bool
    ) throws -> Concept? {
        guard let existing = store.concepts[item.id] else {
            counts.new += 1
            guard !dryRun else { return nil }
            let concept = Concept(externalID: item.id, title: item.title, explanation: item.explanation, resources: item.resources)
            context.insert(concept)
            concept.unit = parent
            concept.tags = try ConceptTag.resolve(names: item.tags, in: context)
            store.concepts[item.id] = concept
            return concept
        }
        let changed = existing.title != item.title
            || existing.explanation != item.explanation
            || existing.resources != item.resources
            || Set((existing.tags ?? []).map(\.name)) != Set(item.tags)
            || existing.unit?.externalID != unitID
        counts.record(changed)
        if changed && !dryRun {
            existing.title = item.title
            existing.explanation = item.explanation
            existing.resources = item.resources
            existing.tags = try ConceptTag.resolve(names: item.tags, in: context)
            existing.unit = parent
        }
        return existing
    }

    private func upsertPrompt(
        _ item: ImportDocument.Prompt,
        conceptID: String,
        parent: Concept?,
        store: inout Store,
        counts: inout ImportPlan.Counts,
        dryRun: Bool
    ) {
        guard let existing = store.prompts[item.id] else {
            counts.new += 1
            guard !dryRun else { return }
            let prompt = Prompt(externalID: item.id, content: item.content, origin: .imported)
            context.insert(prompt)
            prompt.concept = parent
            store.prompts[item.id] = prompt
            return
        }
        let contentChanged = existing.content != item.content
        let changed = contentChanged || existing.concept?.externalID != conceptID
        counts.record(changed)
        guard changed && !dryRun else { return }
        if contentChanged {
            existing.content = item.content
            for variant in existing.variants ?? [] where variant.origin == .aiVariant {
                context.delete(variant)
            }
        }
        existing.concept = parent
    }

    private func upsertExam(_ item: ImportDocument.Exam, store: inout Store, counts: inout ImportPlan.Counts, dryRun: Bool) throws {
        guard let date = item.parsedDate() else { return }
        let existing = store.exams[item.id]
        if let existing {
            let changed = existing.name != item.name
                || existing.date != date
                || existing.course?.externalID != item.courseId
                || Set((existing.units ?? []).map(\.externalID)) != Set(item.unitIds)
                || Set((existing.tags ?? []).map(\.name)) != Set(item.tags)
            counts.record(changed)
            guard changed else { return }
        } else {
            counts.new += 1
        }
        guard !dryRun else { return }

        let exam = existing ?? Exam(externalID: item.id, name: item.name, date: date)
        if existing == nil {
            context.insert(exam)
            store.exams[item.id] = exam
        }
        exam.name = item.name
        exam.date = date
        exam.course = store.courses[item.courseId]
        exam.units = item.unitIds.compactMap { store.units[$0] }
        exam.tags = try ConceptTag.resolve(names: item.tags, in: context)
    }
}

private extension ImportPlan.Counts {
    mutating func record(_ changed: Bool) {
        if changed { updated += 1 } else { unchanged += 1 }
    }
}

/// Existing records indexed by external id.
private struct Store {
    var courses: [String: Course]
    var units: [String: CourseUnit]
    var concepts: [String: Concept]
    var prompts: [String: Prompt]
    var exams: [String: Exam]

    init(context: ModelContext) throws {
        courses = try Self.index(context, \Course.externalID)
        units = try Self.index(context, \CourseUnit.externalID)
        concepts = try Self.index(context, \Concept.externalID)
        prompts = try Self.index(context, \Prompt.externalID)
        exams = try Self.index(context, \Exam.externalID)
    }

    private static func index<Model: PersistentModel>(_ context: ModelContext, _ key: KeyPath<Model, String>) throws -> [String: Model] {
        Dictionary(try context.fetch(FetchDescriptor<Model>()).map { ($0[keyPath: key], $0) }, uniquingKeysWith: { first, _ in first })
    }
}
