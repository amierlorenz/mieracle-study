import Foundation
import SwiftData

/// Writes starter prompts for concepts imported with an explanation but no
/// prompts (the lean import tier), so they can be studied right away.
@MainActor
public struct PromptGenerator {
    private let context: ModelContext
    private let provider: any AIProvider

    public init(context: ModelContext, provider: any AIProvider) {
        self.context = context
        self.provider = provider
    }

    /// Concepts that have an explanation but nothing to study yet.
    public func pendingConcepts() throws -> [Concept] {
        try context.fetch(FetchDescriptor<Concept>()).filter { concept in
            !concept.explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && (concept.prompts ?? []).allSatisfy { $0.origin == .aiVariant }
        }
    }

    /// Generates prompts for each pending concept. Returns the number of concepts filled.
    @discardableResult
    public func run() async throws -> Int {
        guard provider.isAvailable else { return 0 }
        var filled = 0
        for concept in try pendingConcepts() {
            try Task.checkCancellation()
            let contents = try await provider.generatePrompts(title: concept.title, explanation: concept.explanation)
            for content in contents where ImportValidator.problems(in: content).isEmpty {
                let prompt = Prompt(content: content, origin: .aiGenerated)
                context.insert(prompt)
                prompt.concept = concept
            }
            try context.save()
            filled += 1
        }
        return filled
    }
}
