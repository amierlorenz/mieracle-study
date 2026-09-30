import MieracleKit
import SwiftUI

struct AnswerInputView: View {
    let content: PromptContent
    let isRevealed: Bool
    @Binding var input: AnswerInput

    var body: some View {
        if let options = content.options {
            OptionListView(options: options, correct: isRevealed ? content.correctOption : nil, selection: $input.selectedOption)
                .disabled(isRevealed)
        } else {
            switch content {
            case .flashcard:
                EmptyView()
            case .codeComplexity:
                TextField("Time, e.g. O(n log n)", text: $input.time)
                    .disabled(isRevealed)
                TextField("Space, e.g. O(1)", text: $input.space)
                    .disabled(isRevealed)
            case .codeImplement:
                TextField("Your solution", text: $input.text, axis: .vertical)
                    .lineLimit(8...)
                    .monospaced()
                    .disabled(isRevealed)
            default:
                TextField("Your answer", text: $input.text, axis: .vertical)
                    .lineLimit(3...)
                    .disabled(isRevealed)
            }
        }
    }
}
