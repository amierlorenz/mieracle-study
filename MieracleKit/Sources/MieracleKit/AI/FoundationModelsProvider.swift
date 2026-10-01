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
        guard choice == .privateCloud, #available(iOS 27, macOS 27, *) else { return false }
        return PrivateCloudComputeLanguageModel().isAvailable
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

    public func explainChoice(question: String, choice: String, correctChoice: String, context: String) async throws -> String {
        let isCorrect = choice == correctChoice
        let verdict = isCorrect ? "This is the correct answer." : "This answer is wrong; the correct answer is: \(correctChoice)"
        let prompt = """
        Question:
        \(question)

        Answer choice:
        \(choice)

        \(verdict)

        Background from the study material:
        \(context)

        In two or three sentences, explain why this answer choice is \(isCorrect ? "right" : "wrong").
        """
        return try await session(instructions: Self.explanationInstructions).respond(to: prompt).content
    }

    public func suggestShortName(for name: String) async throws -> String {
        let output = try await session(instructions: Self.shortNameInstructions)
            .respond(to: "Class title: \(name)", generating: ShortClassName.self)
            .content
        let code = ClassNameShortener.courseCode(in: name)
        let topic = output.topic.trimmingCharacters(in: .whitespaces)
        guard !topic.isEmpty else { return ClassNameShortener.suggest(for: name) }
        return code.map { "\($0) | \(topic)" } ?? topic
    }

    public func generatePrompts(title: String, explanation: String) async throws -> [PromptContent] {
        let prompt = "Concept: \(title)\n\nExplanation:\n\(explanation)"
        let output = try await session(instructions: Self.generationInstructions)
            .respond(to: prompt, generating: GeneratedPrompts.self)
            .content
        return [
            .flashcard(.init(front: output.flashcardFront, back: output.flashcardBack)),
            .shortAnswer(.init(question: output.question, modelAnswer: output.modelAnswer, keyPoints: output.keyPoints)),
        ]
    }

    private func session(instructions: String) -> LanguageModelSession {
        if usesPrivateCloud, #available(iOS 27, macOS 27, *) {
            return LanguageModelSession(model: PrivateCloudComputeLanguageModel(), instructions: instructions)
        }
        return LanguageModelSession(model: .default, instructions: instructions)
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

    static let explanationInstructions = """
    You are a patient tutor. Explain why a multiple-choice answer is right or wrong, plainly and briefly.
    Stay consistent with the stated correct answer and the background material. Address the student directly.
    """

    static let shortNameInstructions = """
    You shorten long college class titles for a compact label.
    Give the core subject in one or two words, the way a student would say it ("Swift", "Info Assurance", "Operating Systems", "Physics", "Statistics").
    Ignore section numbers, terms, course codes, and words like Intro, Advanced, or Principles.
    """

    static let generationInstructions = """
    You write study questions from a concept and its explanation, for spaced-repetition practice.
    Use only facts stated in the explanation. Questions must require recall, not recognition.
    The flashcard asks for one key fact. The short-answer question asks why or how, and its key points are what a correct answer must mention.
    Keep any LaTeX ($...$) and code exactly as written.
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
struct GeneratedPrompts {
    @Guide(description: "Flashcard question asking for one key fact")
    var flashcardFront: String
    @Guide(description: "Flashcard answer, one or two sentences")
    var flashcardBack: String
    @Guide(description: "A why or how question about the concept")
    var question: String
    @Guide(description: "Model answer to that question, two or three sentences")
    var modelAnswer: String
    @Guide(description: "Points a correct answer must mention", .count(2...4))
    var keyPoints: [String]
}

@Generable
struct ShortClassName {
    @Guide(description: "The class's core subject in one or two words")
    var topic: String
}

@Generable
struct Rephrasings {
    @Guide(description: "Reworded versions of the question", .maximumCount(3))
    var questions: [String]
}
