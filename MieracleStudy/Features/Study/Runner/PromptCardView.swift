import MieracleKit
import SwiftUI

/// One prompt: answer, optionally rate confidence, reveal, then grade.
struct PromptCardView: View {
    let prompt: Prompt
    let concept: Concept
    let mode: StudyMode
    let asksConfidence: Bool
    let onGrade: (Grade, Confidence?, TimeInterval) -> Void

    @State private var input = AnswerInput()
    @State private var isRevealed = false
    @State private var confidence: Confidence?
    @State private var shownAt = Date.now

    var body: some View {
        if let content = prompt.content {
            Form {
                Section {
                    RichTextView(markdown: content.questionMarkdown)
                    AnswerInputView(content: content, isRevealed: isRevealed, input: $input)
                } header: {
                    Text(prompt.kind.displayName)
                }
                if isRevealed {
                    Section("Answer") {
                        RevealedAnswerView(content: content)
                    }
                    ExplanationSection(concept: concept, startsExpanded: mode == .learnNew)
                    Section {
                        GradeButtonsView(suggested: content.suggestedGrade(for: input), onGrade: grade)
                    }
                } else {
                    Section {
                        if asksConfidence {
                            ConfidenceButtonsView(onPick: reveal)
                        } else {
                            Button("Show Answer", action: reveal)
                                .keyboardShortcut(.return, modifiers: .command)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        } else {
            ContentUnavailableView("Unreadable Prompt", systemImage: "exclamationmark.triangle", description: Text("Grade it Again and fix it in the Library."))
            GradeButtonsView(suggested: .again, onGrade: grade)
        }
    }

    private func reveal() {
        isRevealed = true
    }

    private func reveal(with confidence: Confidence) {
        self.confidence = confidence
        isRevealed = true
    }

    private func grade(_ grade: Grade) {
        onGrade(grade, confidence, Date.now.timeIntervalSince(shownAt))
    }
}
