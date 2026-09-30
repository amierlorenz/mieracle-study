import Foundation

/// What a study session covers and how it runs.
public struct SessionConfig: Codable, Hashable, Sendable {
    /// Which content is eligible. A concept matches if its course, its unit,
    /// or any of its tags is selected; an empty scope matches everything.
    public struct Scope: Codable, Hashable, Sendable {
        public var courseIDs: Set<String>
        public var unitIDs: Set<String>
        public var tags: Set<String>

        public init(courseIDs: Set<String> = [], unitIDs: Set<String> = [], tags: Set<String> = []) {
            self.courseIDs = courseIDs
            self.unitIDs = unitIDs
            self.tags = tags
        }

        public var isEmpty: Bool { courseIDs.isEmpty && unitIDs.isEmpty && tags.isEmpty }

        public func contains(_ concept: ConceptSnapshot) -> Bool {
            isEmpty
                || courseIDs.contains(concept.courseID)
                || unitIDs.contains(concept.unitID)
                || !tags.isDisjoint(with: concept.tags)
        }
    }

    public enum Length: Codable, Hashable, Sendable {
        case count(Int)
        case minutes(Int)
        case all
    }

    public enum Order: String, Codable, CaseIterable, Sendable {
        /// Mixed across units, avoiding two items in a row from the same unit.
        case interleaved
        /// Grouped by unit in course order.
        case blocked
        /// Lowest ease and most lapses first.
        case hardestFirst
    }

    public var scope: Scope
    public var mode: StudyMode
    public var length: Length
    public var order: Order
    public var promptKinds: Set<PromptKind>

    public init(
        scope: Scope = .init(),
        mode: StudyMode = .review,
        length: Length = .all,
        order: Order = .interleaved,
        promptKinds: Set<PromptKind> = Set(PromptKind.allCases)
    ) {
        self.scope = scope
        self.mode = mode
        self.length = length
        self.order = order
        self.promptKinds = promptKinds
    }

    public func encoded() -> Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    public static func decoded(from data: Data) -> SessionConfig? {
        try? JSONDecoder().decode(SessionConfig.self, from: data)
    }
}
