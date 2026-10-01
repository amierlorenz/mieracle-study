import Foundation

/// Access to a language model for grading and rewording.
///
/// Every caller must also work when ``isAvailable`` is `false`.
public protocol AIProvider: Sendable {
    var isAvailable: Bool { get }

    /// Suggests a grade for a free-text answer.
    func grade(_ request: GradingRequest) async throws -> GradeSuggestion

    /// Rewords a question without changing what it asks or its correct answer.
    func rephrase(question: String, answer: String, count: Int) async throws -> [String]

    /// Explains in two or three sentences why one answer choice is right or wrong.
    func explainChoice(question: String, choice: String, correctChoice: String, context: String) async throws -> String

    /// Writes starter prompts for a concept that only has an explanation.
    func generatePrompts(title: String, explanation: String) async throws -> [PromptContent]
}

public struct GradingRequest: Hashable, Sendable {
    public var question: String
    public var modelAnswer: String
    public var keyPoints: [String]
    public var answer: String

    public init(question: String, modelAnswer: String, keyPoints: [String] = [], answer: String) {
        self.question = question
        self.modelAnswer = modelAnswer
        self.keyPoints = keyPoints
        self.answer = answer
    }

    /// An answer this short can't be right, so it's graded without asking a model.
    public var isBlank: Bool {
        answer.trimmingCharacters(in: .whitespacesAndNewlines).count < 2
    }
}

public struct GradeSuggestion: Hashable, Sendable {
    public var grade: Grade
    public var missedKeyPoints: [String]
    public var feedback: String

    public init(grade: Grade, missedKeyPoints: [String] = [], feedback: String) {
        self.grade = grade
        self.missedKeyPoints = missedKeyPoints
        self.feedback = feedback
    }

    public static let blank = GradeSuggestion(grade: .again, feedback: "No answer given.")
}
