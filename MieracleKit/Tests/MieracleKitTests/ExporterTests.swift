import Foundation
import MieracleKit
import SwiftData
import Testing

@MainActor
struct ExporterTests {
    @Test func exportRoundTripsIntoEmptyStore() throws {
        let sample = try ImportDocument.decode(from: ImportDocumentTests.fixture())
        let source = try ModelContainerFactory.make(storage: .inMemory)
        try Importer(context: source.mainContext).apply(sample)

        let exported = try Exporter(context: source.mainContext).document()
        let reloaded = try ImportDocument.decode(from: exported.encoded())

        let target = try ModelContainerFactory.make(storage: .inMemory)
        try Importer(context: target.mainContext).apply(reloaded)
        let reexported = try Exporter(context: target.mainContext).document()

        #expect(reexported == exported)
        #expect(exported.courses.flatMap { $0.units.flatMap(\.concepts) }.flatMap(\.prompts).count == 6)
        #expect(try Importer(context: source.mainContext).plan(exported).hasChanges == false)
    }

    @Test func skipsAIVariants() throws {
        let container = try ModelContainerFactory.make(storage: .inMemory)
        let context = container.mainContext
        let concept = Concept(externalID: "k", title: "K")
        let unit = CourseUnit(externalID: "u", name: "U")
        let course = Course(externalID: "c", name: "C")
        context.insert(course)
        unit.course = course
        concept.unit = unit
        let original = Prompt(externalID: "p", content: .flashcard(.init(front: "Q", back: "A")))
        original.concept = concept
        let variant = Prompt(content: .flashcard(.init(front: "Q2", back: "A")), origin: .aiVariant)
        variant.concept = concept
        try context.save()

        let prompts = try Exporter(context: context).document().courses[0].units[0].concepts[0].prompts
        #expect(prompts.map(\.id) == ["p"])
    }
}
