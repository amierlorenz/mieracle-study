import Foundation

/// A value copy of what the session builder needs from a concept, so building
/// is a pure function that's easy to test.
public struct ConceptSnapshot: Hashable, Sendable {
    public var id: String
    public var courseID: String
    public var unitID: String
    public var unitSortIndex: Int
    public var tags: Set<String>
    public var isNew: Bool
    public var dueDate: Date?
    public var ease: Double
    public var lapses: Int
    public var createdAt: Date
    public var prompts: [PromptSnapshot]

    public init(
        id: String,
        courseID: String,
        unitID: String,
        unitSortIndex: Int = 0,
        tags: Set<String> = [],
        isNew: Bool = true,
        dueDate: Date? = nil,
        ease: Double = 2.5,
        lapses: Int = 0,
        createdAt: Date = .distantPast,
        prompts: [PromptSnapshot]
    ) {
        self.id = id
        self.courseID = courseID
        self.unitID = unitID
        self.unitSortIndex = unitSortIndex
        self.tags = tags
        self.isNew = isNew
        self.dueDate = dueDate
        self.ease = ease
        self.lapses = lapses
        self.createdAt = createdAt
        self.prompts = prompts
    }

    public init(_ concept: Concept) {
        self.init(
            id: concept.externalID,
            courseID: concept.unit?.course?.externalID ?? "",
            unitID: concept.unit?.externalID ?? "",
            unitSortIndex: concept.unit?.sortIndex ?? 0,
            tags: Set((concept.tags ?? []).map(\.name)),
            isNew: concept.isNew,
            dueDate: concept.dueDate,
            ease: concept.ease,
            lapses: concept.lapses,
            createdAt: concept.createdAt,
            prompts: (concept.prompts ?? []).map(PromptSnapshot.init)
        )
    }
}

public struct PromptSnapshot: Hashable, Sendable {
    public var id: String
    public var kind: PromptKind
    public var isFlagged: Bool
    public var lastShownAt: Date?

    public init(id: String, kind: PromptKind, isFlagged: Bool = false, lastShownAt: Date? = nil) {
        self.id = id
        self.kind = kind
        self.isFlagged = isFlagged
        self.lastShownAt = lastShownAt
    }

    public init(_ prompt: Prompt) {
        self.init(id: prompt.externalID, kind: prompt.kind, isFlagged: prompt.isFlagged, lastShownAt: prompt.lastShownAt)
    }
}

/// One step of a session: a concept and the prompt chosen to test it.
public struct SessionItem: Hashable, Sendable {
    public var conceptID: String
    public var promptID: String
    public var unitID: String

    public init(conceptID: String, promptID: String, unitID: String) {
        self.conceptID = conceptID
        self.promptID = promptID
        self.unitID = unitID
    }
}
