import MieracleKit
import SwiftUI

/// One prompt: answer, optionally rate confidence, check or get the answer, then grade.
struct PromptCardView: View {
    let prompt: Prompt
    let concept: Concept
    let mode: StudyMode
    let showsConfidence: Bool
    let blursChoices: Bool
    let provider: any AIProvider
    let onGrade: (Grade, Confidence?, TimeInterval) -> Void

    @State private var input = AnswerInput()
    @State private var isRevealed = false
    @State private var gaveUp = false
    @State private var confidence: Confidence?
    @State private var aiSuggestion: GradeSuggestion?
    @State private var codeResult: CodeRunResult?
    @State private var shownAt = Date.now

    var body: some View {
        if let content = prompt.content {
            Form {
                Section {
                    RichTextView(markdown: content.questionMarkdown)
                } header: {
                    Text(prompt.kind.displayName)
                } footer: {
                    FlagPromptButton(prompt: prompt)
                }
                AnswerArea(
                    content: content,
                    isRevealed: isRevealed,
                    blursChoices: blursChoices,
                    input: $input,
                    explainChoice: isRevealed && provider.isAvailable ? { await explainChoice($0, in: content) } : nil
                )
                if case .codeImplement(let problem) = content {
                    CodeRunSection(problem: problem, source: input.text, result: $codeResult)
                }
                if isRevealed {
                    revealedSections(for: content)
                } else {
                    Section {
                    } header: {
                        VStack(spacing: 16) {
                            if showsConfidence {
                                ConfidencePicker(selection: $confidence)
                            }
                            PrimaryActionButtons(
                                primaryTitle: content.kind == .flashcard ? "Show Answer" : "Check Answer",
                                isPrimaryDisabled: content.options != nil && input.selectedOption == nil,
                                primary: reveal,
                                secondaryTitle: content.allowsGettingAnswer ? "Get Answer" : nil,
                                secondary: giveUp
                            )
                        }
                        .textCase(nil)
                        .foregroundStyle(.primary)
                        .padding(.vertical, 8)
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

    @ViewBuilder
    private func revealedSections(for content: PromptContent) -> some View {
        Section("Answer") {
            RevealedAnswerView(content: content, input: input)
        }
        if !gaveUp, provider.isAvailable, let request = content.gradingRequest(for: input) {
            AIGradeSection(request: request, provider: provider, suggestion: $aiSuggestion)
        }
        ExplanationSection(concept: concept, startsExpanded: mode == .learnNew || gaveUp)
        Section {
            GradeButtonsView(suggested: suggestedGrade(for: content), onGrade: grade)
        }
    }

    private func suggestedGrade(for content: PromptContent) -> Grade? {
        if gaveUp { return .again }
        return content.suggestedGrade(for: input) ?? codeResult?.suggestedGrade ?? aiSuggestion?.grade
    }

    private func prefill(from content: PromptContent) {
        if case .codeImplement(let problem) = content, input.text.isEmpty {
            input.text = StarterCode.withoutImports(problem.starterCode)
        }
    }

    private func reveal() {
        isRevealed = true
    }

    private func giveUp() {
        gaveUp = true
        isRevealed = true
    }

    private func explainChoice(_ index: Int, in content: PromptContent) async -> String? {
        guard let options = content.options, let correct = content.correctOption, options.indices.contains(index) else { return nil }
        return try? await provider.explainChoice(
            question: content.questionText,
            choice: options[index],
            correctChoice: options[correct],
            context: concept.explanation
        )
    }

    private func grade(_ grade: Grade) {
        onGrade(grade, confidence, Date.now.timeIntervalSince(shownAt))
    }
}
