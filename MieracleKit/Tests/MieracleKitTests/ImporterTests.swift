import Foundation
import MieracleKit
import SwiftData
import Testing

@MainActor
struct ImporterTests {
    let container: ModelContainer
    let context: ModelContext
    let importer: Importer
    let sample: ImportDocument

    init() throws {
        container = try ModelContainerFactory.make(storage: .inMemory)
        context = container.mainContext
        importer = Importer(context: context)
        sample = try ImportDocument.decode(from: ImportDocumentTests.fixture())
    }

    func concept(_ id: String) throws -> Concept {
        try #require(try context.fetch(FetchDescriptor<Concept>(predicate: #Predicate { $0.externalID == id })).first)
    }

    @Test func planDoesNotChangeStore() throws {
        let plan = try importer.plan(sample)
        #expect(plan.courses == .init(new: 1))
        #expect(plan.units == .init(new: 2))
        #expect(plan.concepts == .init(new: 2))
        #expect(plan.prompts == .init(new: 6))
        #expect(plan.exams == .init(new: 1))
        #expect(try context.fetchCount(FetchDescriptor<Course>()) == 0)
    }

    @Test func appliesSample() throws {
        try importer.apply(sample)

        let heap = try concept("cs201.heaps.heap-property")
        #expect(heap.unit?.externalID == "cs201.heaps")
        #expect(heap.unit?.course?.name == "CS 201 Data Structures")
        #expect(heap.prompts?.count == 3)
        #expect(heap.prompts?.allSatisfy { $0.origin == .imported } == true)
        #expect(heap.tags?.map(\.name) == ["exam2"])
        #expect(heap.resources.first?.title == "Visualgo")

        let exam = try #require(try context.fetch(FetchDescriptor<Exam>()).first)
        #expect(exam.course?.externalID == "cs201")
        #expect(exam.units?.map(\.externalID) == ["cs201.heaps"])
        #expect(exam.covers(heap))
    }

    @Test func reimportIsIdempotent() throws {
        try importer.apply(sample)
        let plan = try importer.plan(sample)
        #expect(!plan.hasChanges)
        #expect(plan.prompts == .init(unchanged: 6))

        try importer.apply(sample)
        #expect(try context.fetchCount(FetchDescriptor<Prompt>()) == 6)
        #expect(try context.fetchCount(FetchDescriptor<ConceptTag>()) == 1)
    }

    @Test func updatesInPlaceAndKeepsHistory() throws {
        try importer.apply(sample)
        let heap = try concept("cs201.heaps.heap-property")
        heap.repetitions = 4
        heap.dueDate = .distantFuture
        let log = ReviewLog(grade: .good, duration: 3, mode: .review, wasDue: true, wasNew: false)
        log.concept = heap
        try context.save()

        var edited = sample
        edited.courses[0].units[0].concepts[0].title = "Min-heap property"
        edited.courses[0].units[0].concepts[0].prompts[0].content = .flashcard(.init(front: "Where is the min?", back: "Root"))
        let plan = try importer.apply(edited)

        #expect(plan.concepts == .init(updated: 1, unchanged: 1))
        #expect(plan.prompts == .init(updated: 1, unchanged: 5))
        #expect(heap.title == "Min-heap property")
        #expect(heap.repetitions == 4)
        #expect(heap.dueDate == .distantFuture)
        #expect(heap.reviews?.count == 1)
    }

    @Test func changedContentRemovesStaleVariants() throws {
        try importer.apply(sample)
        let source = try #require(try concept("cs201.heaps.heap-property").prompts?.first { $0.externalID == "cs201.heaps.heap-property.fc" })
        let variant = Prompt(content: .flashcard(.init(front: "Reworded", back: "At the root.")), origin: .aiVariant)
        variant.concept = source.concept
        variant.sourcePrompt = source
        try context.save()

        var edited = sample
        edited.courses[0].units[0].concepts[0].prompts[0].content = .flashcard(.init(front: "Where is the minimum?", back: "Index 0"))
        try importer.apply(edited)

        #expect(source.variants?.isEmpty == true)
        #expect(try context.fetchCount(FetchDescriptor<Prompt>()) == 6)
    }

    @Test func movesConceptBetweenUnits() throws {
        try importer.apply(sample)
        var edited = sample
        let moved = edited.courses[0].units[0].concepts.removeLast()
        edited.courses[0].units[1].concepts.append(moved)

        let plan = try importer.apply(edited)

        #expect(plan.concepts == .init(updated: 1, unchanged: 1))
        #expect(try concept("cs201.heaps.top-k").unit?.externalID == "cs201.graphs")
    }

    @Test func refusesInvalidDocument() throws {
        var broken = sample
        broken.schemaVersion = 99
        #expect(throws: Importer.Failure.self) {
            try importer.apply(broken)
        }
        #expect(try context.fetchCount(FetchDescriptor<Course>()) == 0)
    }

    @Test func examOnlyImportReferencesStoredUnits() throws {
        try importer.apply(sample)
        let final = ImportDocument(courses: [], exams: [
            .init(id: "cs201.final", courseId: "cs201", name: "Final", date: "2026-12-12", unitIds: ["cs201.heaps", "cs201.graphs"]),
        ])
        let plan = try importer.apply(final)
        #expect(plan.exams == .init(new: 1))
        let exam = try #require(try context.fetch(FetchDescriptor<Exam>(predicate: #Predicate { $0.externalID == "cs201.final" })).first)
        #expect(exam.units?.count == 2)
    }
}
