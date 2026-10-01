import Foundation
import MieracleKit
import SwiftData
import Testing

@MainActor
struct PromptGeneratorTests {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        container = try ModelContainerFactory.make(storage: .inMemory)
        context = container.mainContext
        let lean = ImportDocument(courses: [.init(id: "c", name: "C", units: [.init(id: "c.u", name: "U", concepts: [
            .init(id: "c.u.lean", title: "Spacing", explanation: "Space out practice.", prompts: []),
            .init(id: "c.u.empty", title: "Empty", explanation: "", prompts: []),
            .init(id: "c.u.full", title: "Full", explanation: "Has one.", prompts: [.init(id: "c.u.full.fc", content: .flashcard(.init(front: "Q", back: "A")))]),
        ])])])
        try Importer(context: context).apply(lean)
    }

    @Test func fillsOnlyConceptsWithExplanationAndNoPrompts() async throws {
        let filled = try await PromptGenerator(context: context, provider: MockAIProvider()).run()

        #expect(filled == 1)
        let concepts = try context.fetch(FetchDescriptor<Concept>())
        let lean = try #require(concepts.first { $0.externalID == "c.u.lean" })
        #expect(lean.prompts?.map(\.kind).sorted { $0.rawValue < $1.rawValue } == [.flashcard, .shortAnswer])
        #expect(lean.prompts?.allSatisfy { $0.origin == .aiGenerated } == true)
        #expect(concepts.first { $0.externalID == "c.u.empty" }?.prompts?.isEmpty == true)
        #expect(concepts.first { $0.externalID == "c.u.full" }?.prompts?.count == 1)
    }

    @Test func runningAgainDoesNothing() async throws {
        let provider = MockAIProvider()
        try await PromptGenerator(context: context, provider: provider).run()
        #expect(try await PromptGenerator(context: context, provider: provider).run() == 0)
        #expect(provider.callCount == 1)
    }

    @Test func exportKeepsGeneratedPrompts() async throws {
        try await PromptGenerator(context: context, provider: MockAIProvider()).run()
        let concepts = try Exporter(context: context).document().courses[0].units[0].concepts
        #expect(concepts.first { $0.id == "c.u.lean" }?.prompts.count == 2)
    }
}
