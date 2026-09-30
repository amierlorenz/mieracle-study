import Foundation
import MieracleKit
import SwiftData
import Testing

@MainActor
struct ModelTests {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        container = try ModelContainerFactory.make(storage: .inMemory)
        context = container.mainContext
    }

    func makeTree() throws -> (Course, CourseUnit, Concept, Prompt) {
        let course = Course(name: "CS 101")
        let unit = CourseUnit(name: "Recursion", sortIndex: 1)
        let concept = Concept(title: "Base case")
        let prompt = Prompt(content: .flashcard(.init(front: "Q", back: "A")))
        context.insert(course)
        unit.course = course
        concept.unit = unit
        prompt.concept = concept
        try context.save()
        return (course, unit, concept, prompt)
    }

    @Test func buildsHierarchy() throws {
        let (course, unit, concept, prompt) = try makeTree()
        #expect(course.units?.first === unit)
        #expect(unit.concepts?.first === concept)
        #expect(concept.prompts?.first === prompt)
        #expect(prompt.kind == .flashcard)
        #expect(concept.isNew)
    }

    @Test func deletingCourseCascades() throws {
        let (course, _, concept, _) = try makeTree()
        let log = ReviewLog(grade: .good, duration: 3, mode: .review, wasDue: true, wasNew: true)
        log.concept = concept
        try context.save()

        context.delete(course)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<CourseUnit>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Concept>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Prompt>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ReviewLog>()) == 0)
    }

    @Test func deletingPromptKeepsReviewHistory() throws {
        let (_, _, concept, prompt) = try makeTree()
        let log = ReviewLog(grade: .hard, duration: 5, mode: .practice, wasDue: false, wasNew: false)
        log.concept = concept
        log.prompt = prompt
        try context.save()

        context.delete(prompt)
        try context.save()

        let logs = try context.fetch(FetchDescriptor<ReviewLog>())
        #expect(logs.count == 1)
        #expect(logs.first?.prompt == nil)
        #expect(logs.first?.concept === concept)
    }

    @Test func variantsBelongToSourcePrompt() throws {
        let (_, _, concept, prompt) = try makeTree()
        let variant = Prompt(content: .flashcard(.init(front: "Q reworded", back: "A")), origin: .aiVariant)
        variant.concept = concept
        variant.sourcePrompt = prompt
        try context.save()

        #expect(prompt.variants?.first === variant)
        #expect(concept.prompts?.count == 2)
    }

    @Test func updatingContentUpdatesKind() throws {
        let (_, _, _, prompt) = try makeTree()
        prompt.content = .shortAnswer(.init(question: "Why?", modelAnswer: "Because"))
        #expect(prompt.kind == .shortAnswer)
        #expect(prompt.content?.questionText == "Why?")
    }

    @Test func examCoversConceptsByUnitOrTag() throws {
        let (course, unit, concept, _) = try makeTree()
        let other = Concept(title: "Heaps")
        let otherUnit = CourseUnit(name: "Trees", sortIndex: 2)
        otherUnit.course = course
        other.unit = otherUnit
        let tag = ConceptTag(name: "exam2")
        other.tags = [tag]

        let exam = Exam(name: "Midterm", date: .now)
        exam.course = course
        exam.units = [unit]
        context.insert(exam)
        try context.save()

        #expect(exam.covers(concept))
        #expect(!exam.covers(other))

        exam.tags = [tag]
        #expect(exam.covers(other))
        #expect(unit.exams?.first === exam)
    }

    @Test func sortedUnitsFollowSortIndex() throws {
        let course = Course(name: "Math")
        context.insert(course)
        for (name, index) in [("C", 3), ("A", 1), ("B", 2)] {
            let unit = CourseUnit(name: name, sortIndex: index)
            unit.course = course
        }
        try context.save()
        #expect(course.sortedUnits.map(\.name) == ["A", "B", "C"])
    }
}
