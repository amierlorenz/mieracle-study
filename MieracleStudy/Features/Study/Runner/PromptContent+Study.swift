import MieracleKit

extension PromptContent {
    /// Markdown shown as the question.
    var questionMarkdown: String {
        switch self {
        case .flashcard(let c): c.front
        case .shortAnswer(let c): c.question
        case .multipleChoice(let c): c.question
        case .codeImplement(let c): "\(c.statement)\n\n```\(c.language.rawValue)\n\(c.starterCode)\n```"
        case .codeComplexity(let c): "What are the time and space complexity?\n\n```\(c.language.rawValue)\n\(c.code)\n```"
        case .patternPick(let c): "\(c.statement)\n\nWhich approach or data structure fits, and why?"
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

    /// A grade the app can infer on its own, before the learner confirms.
    func suggestedGrade(for input: AnswerInput) -> Grade? {
        guard let correct = correctOption, let selected = input.selectedOption else { return nil }
        return selected == correct ? .good : .again
    }
}
