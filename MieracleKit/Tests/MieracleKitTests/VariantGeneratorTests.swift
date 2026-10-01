import Foundation
import MieracleKit
import SwiftData
import Testing

@MainActor
struct VariantGeneratorTests {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        container = try ModelContainerFactory.make(storage: .inMemory)
        context = container.mainContext
        try Importer(context: context).apply(ImportDocument.decode(from: ImportDocumentTests.fixture()))
    }

    func variants() throws -> [Prompt] {
        try context.fetch(FetchDescriptor<Prompt>()).filter { $0.origin == .aiVariant }
    }

    @Test func fillsEligibleConceptsUpToLimit() async throws {
        let created = try await VariantGenerator(context: context, provider: MockAIProvider()).run()

        #expect(created == VariantGenerator.maxVariantsPerConcept)
        let all = try variants()
        #expect(all.allSatisfy { $0.concept?.externalID == "cs201.heaps.heap-property" })
        #expect(all.allSatisfy { $0.kind == .flashcard || $0.kind == .shortAnswer })
    }

    @Test func variantsKeepTheSourceAnswer() async throws {
        try await VariantGenerator(context: context, provider: MockAIProvider()).run()
        for variant in try variants() {
            let source = try #require(variant.sourcePrompt?.content)
            let content = try #require(variant.content)
            #expect(content.answerText == source.answerText)
            #expect(content.questionText != source.questionText)
            if case .shortAnswer(let v) = content, case .shortAnswer(let s) = source {
                #expect(v.keyPoints == s.keyPoints)
            }
        }
    }

    @Test func skipsDuplicateRewordings() async throws {
        let echo = MockAIProvider(rephrasings: { question, _ in [question.uppercased()] })
        #expect(try await VariantGenerator(context: context, provider: echo).run() == 0)
    }

    @Test func doesNothingWhenUnavailable() async throws {
        let offline = MockAIProvider(isAvailable: false)
        #expect(try await VariantGenerator(context: context, provider: offline).run() == 0)
        #expect(offline.callCount == 0)
    }

    @Test func flaggedSourcesAreNotReworded() async throws {
        for prompt in try context.fetch(FetchDescriptor<Prompt>()) {
            prompt.isFlagged = true
        }
        #expect(try await VariantGenerator(context: context, provider: MockAIProvider()).run() == 0)
    }

    @Test func secondRunAddsNothing() async throws {
        let provider = MockAIProvider()
        try await VariantGenerator(context: context, provider: provider).run()
        let calls = provider.callCount
        #expect(try await VariantGenerator(context: context, provider: provider).run() == 0)
        #expect(provider.callCount == calls)
    }
}
