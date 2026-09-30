import Foundation
import SwiftData

/// One idea to learn. Concepts are the unit of scheduling: each has a single
/// review schedule shared by all of its prompts.
@Model
public final class Concept {
    #Index<Concept>([\.externalID], [\.dueDate])

    public var externalID: String = UUID().uuidString
    public var title: String = ""
    /// Markdown with optional LaTeX, shown after answering.
    public var explanation: String = ""
    public var resources: [Resource] = []
    public var createdAt: Date = Date.now

    public var ease: Double = 2.5
    public var intervalDays: Double = 0
    public var repetitions: Int = 0
    public var lapses: Int = 0
    public var dueDate: Date?
    public var lastReviewedAt: Date?
    /// When the concept was first studied; `nil` means the concept is new.
    public var introducedAt: Date?

    public var unit: CourseUnit?

    @Relationship(deleteRule: .nullify, inverse: \ConceptTag.concepts)
    public var tags: [ConceptTag]? = []

    @Relationship(deleteRule: .cascade, inverse: \Prompt.concept)
    public var prompts: [Prompt]? = []

    @Relationship(deleteRule: .cascade, inverse: \ReviewLog.concept)
    public var reviews: [ReviewLog]? = []

    public init(
        externalID: String = UUID().uuidString,
        title: String,
        explanation: String = "",
        resources: [Resource] = []
    ) {
        self.externalID = externalID
        self.title = title
        self.explanation = explanation
        self.resources = resources
    }

    public var isNew: Bool { introducedAt == nil }
}

/// A link to outside material about a concept.
public struct Resource: Codable, Hashable, Sendable {
    public var title: String
    public var url: URL

    public init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
}
