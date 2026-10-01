import Foundation
import SwiftData

/// One way of testing a concept: a flashcard, question, or coding exercise.
///
/// The payload is stored as JSON in ``contentData`` and exposed through ``content``,
/// so new prompt kinds never require a schema change.
@Model
public final class Prompt {
    #Index<Prompt>([\.externalID], [\.kindRaw])

    public var externalID: String = UUID().uuidString
    public var kindRaw: String = PromptKind.flashcard.rawValue
    public var contentData: Data = Data()
    public var originRaw: String = PromptOrigin.manual.rawValue
    /// Flagged variants are excluded from study until reviewed.
    public var isFlagged: Bool = false
    public var lastShownAt: Date?
    public var createdAt: Date = Date.now

    public var concept: Concept?

    /// The prompt this one was reworded from, for AI variants.
    public var sourcePrompt: Prompt?

    @Relationship(deleteRule: .cascade, inverse: \Prompt.sourcePrompt)
    public var variants: [Prompt]? = []

    @Relationship(deleteRule: .nullify, inverse: \ReviewLog.prompt)
    public var reviews: [ReviewLog]? = []

    public init(externalID: String = UUID().uuidString, content: PromptContent, origin: PromptOrigin = .manual) {
        self.externalID = externalID
        self.originRaw = origin.rawValue
        self.content = content
    }

    public var kind: PromptKind {
        PromptKind(rawValue: kindRaw) ?? .flashcard
    }

    public var origin: PromptOrigin {
        get { PromptOrigin(rawValue: originRaw) ?? .manual }
        set { originRaw = newValue.rawValue }
    }

    /// The decoded payload. Returns `nil` only if stored data is corrupt.
    public var content: PromptContent? {
        get { try? JSONDecoder().decode(PromptContent.self, from: contentData) }
        set {
            guard let newValue, let data = try? JSONEncoder().encode(newValue) else { return }
            contentData = data
            kindRaw = newValue.kind.rawValue
        }
    }
}

/// Where a prompt came from.
public enum PromptOrigin: String, Codable, CaseIterable, Sendable {
    case imported
    case manual
    /// A reworded copy of another prompt.
    case aiVariant
    /// Written by AI from a concept's explanation (lean imports).
    case aiGenerated
}
