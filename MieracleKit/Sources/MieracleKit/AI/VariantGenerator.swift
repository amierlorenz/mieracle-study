import Foundation
import SwiftData

/// Adds AI-reworded variants of flashcard and short-answer prompts so a
/// concept isn't always tested with the same sentence.
///
/// Variants copy the source prompt's answer fields verbatim; only the question
/// changes. Each pass adds at most one variant per concept, so every concept
/// gets some variety before any concept gets a lot.
@MainActor
public struct VariantGenerator {
    public static let maxVariantsPerConcept = 3

    private let context: ModelContext
    private let provider: any AIProvider

    public init(context: ModelContext, provider: any AIProvider) {
        self.context = context
        self.provider = provider
    }

    /// Generates until every eligible concept has its variants, the provider
    /// becomes unavailable, or the task is cancelled. Returns the number created.
    @discardableResult
    public func run() async throws -> Int {
        var created = 0
        var exhausted: Set<PersistentIdentifier> = []
        while provider.isAvailable {
            let sources = try nextSources(skipping: exhausted)
            guard !sources.isEmpty else { break }
            for source in sources {
                try Task.checkCancellation()
                if try await addVariant(of: source) {
                    created += 1
                } else {
                    exhausted.insert(source.persistentModelID)
                }
            }
            try context.save()
        }
        return created
    }

    /// One source prompt per concept that still has room for variants.
    func nextSources(skipping exhausted: Set<PersistentIdentifier>) throws -> [Prompt] {
        try context.fetch(FetchDescriptor<Concept>()).compactMap { concept in
            let prompts = concept.prompts ?? []
            guard prompts.count { $0.origin == .aiVariant } < Self.maxVariantsPerConcept else { return nil }
            return prompts
                .filter { $0.origin != .aiVariant && !$0.isFlagged && !exhausted.contains($0.persistentModelID) && ($0.content?.supportsVariants ?? false) }
                .min { ($0.variants?.count ?? 0, $0.createdAt) < ($1.variants?.count ?? 0, $1.createdAt) }
        }
    }

    private func addVariant(of source: Prompt) async throws -> Bool {
        guard let content = source.content, let answer = content.answerText else { return false }
        let question = content.questionText
        let candidates = try await provider.rephrase(question: question, answer: answer, count: 1)
        let existing = Set(([source] + (source.variants ?? [])).compactMap { $0.content?.questionText }.map(Self.normalized))
        guard let fresh = candidates.first(where: { !existing.contains(Self.normalized($0)) && !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return false
        }
        let variant = Prompt(content: content.replacingQuestion(with: fresh), origin: .aiVariant)
        context.insert(variant)
        variant.concept = source.concept
        variant.sourcePrompt = source
        return true
    }

    private static func normalized(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
