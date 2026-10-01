import MieracleKit
import SwiftUI

/// One prompt: answer, optionally rate confidence, reveal, then grade.
struct PromptCardView: View {
    let prompt: Prompt
    let concept: Concept
    let mode: StudyMode
    let asksConfidence: Bool
    let provider: any AIProvider
    let onGrade: (Grade, Confidence?, TimeInterval) -> Void

    @State private var input = AnswerInput()
    @State private var isRevealed = false
    @State private var confidence: Confidence?
    @State private var aiSuggestion: GradeSuggestion?
    @State private var codeResult: CodeRunResult?
    @State private var shownAt = Date.now

    var body: some View {
        if let content = prompt.content {
            Form {
                Section {
                    RichTextView(markdown: content.questionMarkdown)
                    AnswerInputView(content: content, isRevealed: isRevealed, input: $input)
                } header: {
                    Text(prompt.kind.displayName)
                } footer: {
                    FlagPromptButton(prompt: prompt)
                }
                if case .codeImplement(let problem) = content {
                    CodeRunSection(problem: problem, source: input.text, result: $codeResult)
                }
                if isRevealed {
                    Section("Answer") {
                        RevealedAnswerView(content: content, input: input)
                    }
                    if provider.isAvailable, let request = content.gradingRequest(for: input) {
                        AIGradeSection(request: request, provider: provider, suggestion: $aiSuggestion)
                    }
                    ExplanationSection(concept: concept, startsExpanded: mode == .learnNew)
                    Section {
                        GradeButtonsView(suggested: content.suggestedGrade(for: input) ?? codeResult?.suggestedGrade ?? aiSuggestion?.grade, onGrade: grade)
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
            .onAppear { prefill(from: content) }
        } else {
            ContentUnavailableView("Unreadable Prompt", systemImage: "exclamationmark.triangle", description: Text("Grade it Again and fix it in the Library."))
            GradeButtonsView(suggested: .again, onGrade: grade)
        }
    }

    private func prefill(from content: PromptContent) {
        if case .codeImplement(let problem) = content, input.text.isEmpty {
            input.text = problem.starterCode
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
