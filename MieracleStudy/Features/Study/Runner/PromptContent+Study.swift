import MieracleKit

extension PromptContent {
    /// Markdown shown as the question.
    var questionMarkdown: String {
        switch self {
        case .flashcard(let c): c.front
        case .shortAnswer(let c): c.question
        case .multipleChoice(let c): c.question
        case .codeImplement(let c): c.statement
        case .codeComplexity(let c): "What are the time and space complexity?\n\n```\(c.language.rawValue)\n\(c.code)\n```"
        case .patternPick(let c): "\(c.statement)\n\nWhich approach or data structure fits, and why?"
        case .fullProblem(let c): c.statement
        }
    }

    /// Answer choices, for kinds graded as multiple choice.
    var options: [String]? {
        switch self {
        case .multipleChoice(let c): c.options
        case .patternPick(let c): c.options
        default: nil
        }
    }

    var correctOption: Int? {
        switch self {
        case .multipleChoice(let c): c.correctIndex
        case .patternPick(let c): c.correctIndex
        default: nil
        }
    }

    /// What to send for AI grading, for free-text kinds.
    func gradingRequest(for input: AnswerInput) -> GradingRequest? {
        switch self {
        case .shortAnswer(let c):
            GradingRequest(question: c.question, modelAnswer: c.modelAnswer, keyPoints: c.keyPoints, answer: input.text)
        case .patternPick(let c) where c.options == nil:
            GradingRequest(question: c.statement, modelAnswer: "\(c.answer). \(c.explanation)", keyPoints: [c.answer], answer: input.text)
        default:
            nil
        }
    }

    /// A grade the app can infer on its own, before the learner confirms.
    func suggestedGrade(for input: AnswerInput) -> Grade? {
        if case .codeComplexity(let c) = self {
            let correct = [(input.time, c.time), (input.space, c.space)].count { BigONormalizer.areEquivalent($0, $1) }
            return switch correct {
            case 2: .good
            case 1: .hard
            default: .again
            }
        }
        guard let correct = correctOption, let selected = input.selectedOption else { return nil }
        return selected == correct ? .good : .again
    }
}
