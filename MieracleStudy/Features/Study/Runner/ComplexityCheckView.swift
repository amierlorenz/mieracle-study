import MieracleKit
import SwiftUI

/// Shows whether the learner's time and space answers match.
struct ComplexityCheckView: View {
    let expected: PromptContent.CodeComplexity
    let input: AnswerInput

    var body: some View {
        row("Time", answer: input.time, expected: expected.time)
        row("Space", answer: input.space, expected: expected.space)
    }

    private func row(_ title: String, answer: String, expected: String) -> some View {
        let isCorrect = BigONormalizer.areEquivalent(answer, expected)
        return Label("\(title): \(answer.isEmpty ? "—" : answer)", systemImage: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundStyle(isCorrect ? .green : .red)
    }
}
