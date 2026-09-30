import Foundation
import SwiftData

/// Merges records that share an ``Course/externalID`` (or a tag name).
///
/// CloudKit can't enforce uniqueness, so importing the same content on two
/// devices before they sync produces duplicates. Running this at launch folds
/// each group into one record, keeping children and review history.
public enum DuplicateMerger {
    /// Merges all duplicate groups and saves. Returns the number of records removed.
    @discardableResult
    public static func mergeAll(in context: ModelContext) throws -> Int {
        var removed = 0
        removed += try merge(Course.self, key: \.externalID, in: context, keeper: earliest(\.createdAt), absorb: absorb)
        removed += try merge(CourseUnit.self, key: \.externalID, in: context, keeper: { $0[0] }, absorb: absorb)
        removed += try merge(Concept.self, key: \.externalID, in: context, keeper: mostReviewed, absorb: absorb)
        removed += try merge(Prompt.self, key: \.externalID, in: context, keeper: earliest(\.createdAt), absorb: absorb)
        removed += try merge(Exam.self, key: \.externalID, in: context, keeper: { $0[0] }, absorb: absorb)
        removed += try merge(ConceptTag.self, key: \.name, in: context, keeper: { $0[0] }, absorb: absorb)
        if removed > 0 {
            try context.save()
        }
        return removed
    }

    private static func merge<Model: PersistentModel>(
        _ type: Model.Type,
        key: KeyPath<Model, String>,
        in context: ModelContext,
        keeper choose: ([Model]) -> Model,
        absorb: (Model, Model) -> Void
    ) throws -> Int {
        let groups = Dictionary(grouping: try context.fetch(FetchDescriptor<Model>()), by: { $0[keyPath: key] })
        var removed = 0
        for group in groups.values where group.count > 1 {
            let keeper = choose(group)
            for duplicate in group where duplicate.persistentModelID != keeper.persistentModelID {
                absorb(keeper, duplicate)
                context.delete(duplicate)
                removed += 1
            }
        }
        return removed
    }

    private static func earliest<Model>(_ date: KeyPath<Model, Date>) -> ([Model]) -> Model {
        { group in group.min { $0[keyPath: date] < $1[keyPath: date] } ?? group[0] }
    }

    private static func mostReviewed(_ group: [Concept]) -> Concept {
        group.max { ($0.reviews?.count ?? 0) < ($1.reviews?.count ?? 0) } ?? group[0]
    }

    private static func absorb(_ keeper: Course, _ duplicate: Course) {
        for unit in duplicate.units ?? [] { unit.course = keeper }
        for exam in duplicate.exams ?? [] { exam.course = keeper }
        keeper.canvasCourseID = keeper.canvasCourseID ?? duplicate.canvasCourseID
    }

    private static func absorb(_ keeper: CourseUnit, _ duplicate: CourseUnit) {
        for concept in duplicate.concepts ?? [] { concept.unit = keeper }
        for exam in duplicate.exams ?? [] where !(keeper.exams ?? []).contains(where: { $0 === exam }) {
            keeper.exams?.append(exam)
        }
    }

    private static func absorb(_ keeper: Concept, _ duplicate: Concept) {
        if (duplicate.lastReviewedAt ?? .distantPast) > (keeper.lastReviewedAt ?? .distantPast) {
            keeper.ease = duplicate.ease
            keeper.intervalDays = duplicate.intervalDays
            keeper.repetitions = duplicate.repetitions
            keeper.lapses = duplicate.lapses
            keeper.dueDate = duplicate.dueDate
            keeper.lastReviewedAt = duplicate.lastReviewedAt
        }
        keeper.introducedAt = [keeper.introducedAt, duplicate.introducedAt].compactMap { $0 }.min()
        for prompt in duplicate.prompts ?? [] { prompt.concept = keeper }
        for review in duplicate.reviews ?? [] { review.concept = keeper }
        for tag in duplicate.tags ?? [] where !(keeper.tags ?? []).contains(where: { $0 === tag }) {
            keeper.tags?.append(tag)
        }
    }

    private static func absorb(_ keeper: Prompt, _ duplicate: Prompt) {
        for variant in duplicate.variants ?? [] { variant.sourcePrompt = keeper }
        for review in duplicate.reviews ?? [] { review.prompt = keeper }
        keeper.isFlagged = keeper.isFlagged || duplicate.isFlagged
    }

    private static func absorb(_ keeper: Exam, _ duplicate: Exam) {
        for unit in duplicate.units ?? [] where !(keeper.units ?? []).contains(where: { $0 === unit }) {
            keeper.units?.append(unit)
        }
        for tag in duplicate.tags ?? [] where !(keeper.tags ?? []).contains(where: { $0 === tag }) {
            keeper.tags?.append(tag)
        }
        keeper.canvasItemID = keeper.canvasItemID ?? duplicate.canvasItemID
    }

    private static func absorb(_ keeper: ConceptTag, _ duplicate: ConceptTag) {
        for concept in duplicate.concepts ?? [] {
            concept.tags?.removeAll { $0 === duplicate }
            if !(concept.tags ?? []).contains(where: { $0 === keeper }) {
                concept.tags?.append(keeper)
            }
        }
        for exam in duplicate.exams ?? [] {
            exam.tags?.removeAll { $0 === duplicate }
            if !(exam.tags ?? []).contains(where: { $0 === keeper }) {
                exam.tags?.append(keeper)
            }
        }
    }
}
