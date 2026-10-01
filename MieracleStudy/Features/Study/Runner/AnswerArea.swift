import MieracleKit
import SwiftUI

/// Where the learner answers, shaped by the prompt kind.
struct AnswerArea: View {
    let content: PromptContent
    let isRevealed: Bool
    let blursChoices: Bool
    @Binding var input: AnswerInput
    var explainChoice: ((Int) async -> String?)?

    var body: some View {
        if let options = content.options {
            Section("Choose an answer") {
                CountdownReveal(isEnabled: blursChoices && !isRevealed) {
                    VStack(alignment: .leading, spacing: 12) {
                        OptionListView(
                            options: options,
                            correct: isRevealed ? content.correctOption : nil,
                            selection: $input.selectedOption,
                            explain: explainChoice
                        )
                    }
                }
                .disabled(isRevealed && explainChoice == nil)
            }
        } else {
            switch content {
            case .flashcard, .fullProblem:
                EmptyView()
            case .codeComplexity:
                Section {
                    AnswerField(title: "Time complexity", placeholder: "e.g. O(n log n)", text: $input.time, style: .short, isDisabled: isRevealed)
                    AnswerField(title: "Space complexity", placeholder: "e.g. O(1)", text: $input.space, style: .short, isDisabled: isRevealed)
                }
            case .codeImplement:
                Section {
                    VStack(spacing: 8) {
                        Text("Your solution")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                        CodeEditorField(source: $input.text, isDisabled: isRevealed)
                    }
                }
            case .patternPick:
                Section {
                    AnswerField(title: "Your approach", placeholder: "Approach or data structure, and why", text: $input.text, isDisabled: isRevealed)
                }
            case .shortAnswer, .multipleChoice:
                Section {
                    AnswerField(title: "Your answer", placeholder: "Type your answer", text: $input.text, isDisabled: isRevealed)
                }
            }
        }
    }
}
