import Foundation
import MieracleKit
import SwiftData
import Testing

@MainActor
struct DuplicateMergerTests {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        container = try ModelContainerFactory.make(storage: .inMemory)
        context = container.mainContext
    }

    func insertCopy(reviewed: Bool) -> Course {
        let course = Course(externalID: "cs101", name: "CS 101")
        let unit = CourseUnit(externalID: "cs101.u1", name: "Recursion")
        let concept = Concept(externalID: "cs101.u1.base", title: "Base case")
        let prompt = Prompt(externalID: "cs101.u1.base.fc", content: .flashcard(.init(front: "Q", back: "A")))
        context.insert(course)
        unit.course = course
        concept.unit = unit
        prompt.concept = concept
        if reviewed {
            concept.repetitions = 3
            concept.lastReviewedAt = .now
            concept.introducedAt = .now
            let log = ReviewLog(grade: .good, duration: 2, mode: .review, wasDue: true, wasNew: false)
            log.concept = concept
            log.prompt = prompt
        }
        return course
    }

    @Test func mergesDuplicatedTreeKeepingHistory() throws {
        _ = insertCopy(reviewed: false)
        _ = insertCopy(reviewed: true)
        try context.save()

        let removed = try DuplicateMerger.mergeAll(in: context)

        #expect(removed == 4)
        #expect(try context.fetchCount(FetchDescriptor<Course>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<CourseUnit>()) == 1)
        let concepts = try context.fetch(FetchDescriptor<Concept>())
        #expect(concepts.count == 1)
        #expect(concepts.first?.repetitions == 3)
        #expect(concepts.first?.reviews?.count == 1)
        #expect(concepts.first?.prompts?.count == 1)
        #expect(try context.fetchCount(FetchDescriptor<ReviewLog>()) == 1)
    }

    @Test func noDuplicatesIsNoOp() throws {
        _ = insertCopy(reviewed: true)
        try context.save()
        #expect(try DuplicateMerger.mergeAll(in: context) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Prompt>()) == 1)
    }

    @Test func mergesTagsByName() throws {
        let first = Concept(title: "A")
        let second = Concept(title: "B")
        context.insert(first)
        context.insert(second)
        first.tags = [ConceptTag(name: "exam2")]
        second.tags = [ConceptTag(name: "exam2")]
        try context.save()

        try DuplicateMerger.mergeAll(in: context)

        let tags = try context.fetch(FetchDescriptor<ConceptTag>())
        #expect(tags.count == 1)
        #expect(tags.first?.concepts?.count == 2)
    }
}
