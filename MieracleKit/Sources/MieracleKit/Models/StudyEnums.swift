/// How well a prompt was answered.
public enum Grade: String, Codable, CaseIterable, Sendable {
    case again
    case hard
    case good
    case easy

    public var isPass: Bool { self != .again }
}

/// How sure the learner felt before seeing the answer.
public enum Confidence: String, Codable, CaseIterable, Sendable {
    case sure
    case unsure
    case noIdea
}

/// What a study session draws from.
public enum StudyMode: String, Codable, CaseIterable, Sendable {
    /// Only concepts that are due.
    case review
    /// Anything in scope, due or not.
    case practice
    /// Concepts never studied before.
    case learnNew
}
