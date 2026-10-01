import MieracleKit
import SwiftUI

struct RevealedAnswerView: View {
    let content: PromptContent
    let input: AnswerInput

    var body: some View {
        switch content {
        case .flashcard(let c):
            RichTextView(markdown: c.back)
        case .shortAnswer(let c):
            RichTextView(markdown: c.modelAnswer)
            if !c.keyPoints.isEmpty {
                RichTextView(markdown: "**Key points**\n\n" + c.keyPoints.map { "- \($0)" }.joined(separator: "\n"))
            }
        case .multipleChoice(let c):
            if let explanation = c.explanation {
                RichTextView(markdown: explanation)
            }
        case .codeImplement(let c):
            if let solution = c.referenceSolution {
                RichTextView(markdown: "**Reference solution**\n\n```\(c.language.rawValue)\n\(solution)\n```")
            }
            if let explanation = c.explanation {
                RichTextView(markdown: explanation)
            }
        case .codeComplexity(let c):
            ComplexityCheckView(expected: c, input: input)
            RichTextView(markdown: "**Time** \(c.time) · **Space** \(c.space)\n\n\(c.explanation)")
        case .patternPick(let c):
            RichTextView(markdown: "**\(c.answer)**\n\n\(c.explanation)")
        case .fullProblem(let c):
            RichTextView(markdown: c.revealMarkdown)
        }
    }
}
