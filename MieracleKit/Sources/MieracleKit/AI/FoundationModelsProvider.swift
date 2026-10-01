import Foundation
import FoundationModels

/// ``AIProvider`` backed by Apple's Foundation Models.
///
/// Uses the on-device model, or the larger Private Cloud Compute model when
/// requested and available (it needs the `com.apple.developer.private-cloud-compute`
/// entitlement), falling back to on-device otherwise.
public struct FoundationModelsProvider: AIProvider {
    public enum ModelChoice: String, Sendable, CaseIterable {
        case onDevice
        case privateCloud
    }

    public let choice: ModelChoice

    public init(choice: ModelChoice = .onDevice) {
        self.choice = choice
    }

    public var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable || usesPrivateCloud
    }

    /// The model actually in use after falling back.
    public var activeModel: ModelChoice {
        usesPrivateCloud ? .privateCloud : .onDevice
    }

    private var usesPrivateCloud: Bool {
        choice == .privateCloud && PrivateCloudComputeLanguageModel().isAvailable
    }

    public func grade(_ request: GradingRequest) async throws -> GradeSuggestion {
        if request.isBlank { return .blank }
        let output = try await session(instructions: Self.gradingInstructions)
            .respond(to: Self.gradingPrompt(for: request), generating: GradingOutput.self)
            .content
        return GradeSuggestion(grade: output.grade.grade, missedKeyPoints: output.missedKeyPoints, feedback: output.feedback)
    }

    public func rephrase(question: String, answer: String, count: Int) async throws -> [String] {
        let prompt = """
        Question:
        \(question)

        Its correct answer (keep it exactly correct for every rewording):
        \(answer)

        Write \(count) rewordings of the question.
        """
        let output = try await session(instructions: Self.rephraseInstructions)
            .respond(to: prompt, generating: Rephrasings.self)
            .content
        return Array(output.questions.prefix(count))
    }

    private func session(instructions: String) -> LanguageModelSession {
        if usesPrivateCloud {
            LanguageModelSession(model: PrivateCloudComputeLanguageModel(), instructions: instructions)
        } else {
            LanguageModelSession(model: .default, instructions: instructions)
        }
    }

    static let gradingInstructions = """
    You grade a student's short answer against a model answer and its key points.
    Judge meaning, not wording: accept synonyms, paraphrases, and different order.
    Grades:
    - again: wrong, irrelevant, or missing the core idea.
    - hard: partly right but missing or garbling an important key point.
    - good: correct and covers the essential key points.
    - easy: correct, complete, and precise.
    List only key points that are genuinely missing. Feedback is one short sentence addressed to the student.
    """

    static let rephraseInstructions = """
    You reword study questions so students practice recalling an idea rather than recognizing a sentence.
    Each rewording must test exactly the same knowledge and have exactly the same correct answer.
    Do not reveal or hint at the answer. Do not add new facts.
    Keep any Markdown, LaTeX ($...$), and code exactly as written.
    Vary the phrasing or angle, for example a different sentence structure or a short scenario.
    """

    static func gradingPrompt(for request: GradingRequest) -> String {
        let points = request.keyPoints.isEmpty ? "(none listed)" : request.keyPoints.map { "- \($0)" }.joined(separator: "\n")
        return """
        Question:
        \(request.question)

        Model answer:
        \(request.modelAnswer)

        Key points:
        \(points)

        Student's answer:
        \(request.answer)
        """
    }
}

@Generable
struct GradingOutput {
    @Guide(description: "The grade for the student's answer")
    var grade: GeneratedGrade
    @Guide(description: "Key points the answer is missing; empty if none", .maximumCount(5))
    var missedKeyPoints: [String]
    @Guide(description: "One short sentence of feedback to the student")
    var feedback: String
}

@Generable
enum GeneratedGrade {
    case again
    case hard
    case good
    case easy

    var grade: Grade {
        switch self {
        case .again: .again
        case .hard: .hard
        case .good: .good
        case .easy: .easy
        }
    }
}

@Generable
struct Rephrasings {
    @Guide(description: "Reworded versions of the question", .maximumCount(3))
    var questions: [String]
}
