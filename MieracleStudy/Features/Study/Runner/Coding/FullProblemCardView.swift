import MieracleKit
import SwiftUI

/// A full problem in four stages: pattern, plan, code, complexity.
struct FullProblemCardView: View {
    let prompt: Prompt
    let problem: PromptContent.FullProblem
    let concept: Concept
    let mode: StudyMode
    let blursChoices: Bool
    let onGrade: (Grade, Confidence?, TimeInterval) -> Void

    @State private var stage = 0
    @State private var input = AnswerInput()
    @State private var plan = ""
    @State private var code = ""
    @State private var codeResult: CodeRunResult?
    @State private var shownAt = Date.now

    var body: some View {
        Form {
            Section {
                RichTextView(markdown: problem.statement)
            } header: {
                Text(prompt.kind.displayName)
            } footer: {
                FlagPromptButton(prompt: prompt)
            }
            Section("1. Which approach fits?") {
                if let options = problem.options {
                    CountdownReveal(isEnabled: blursChoices && stage == 0) {
                        VStack(alignment: .leading, spacing: 12) {
                            OptionListView(options: options, correct: stage > 0 ? problem.correctIndex : nil, selection: $input.selectedOption)
                        }
                    }
                    .disabled(stage > 0)
                } else {
                    AnswerField(title: "Your approach", placeholder: "Approach or data structure", text: $input.text, isDisabled: stage > 0)
                }
                if stage > 0 {
                    Text("Pattern: \(problem.pattern)")
                        .bold()
                }
            }
            if stage >= 1 {
                Section("2. Plan it") {
                    AnswerField(title: "Your plan", placeholder: "Steps in plain words", text: $plan, isDisabled: stage > 1)
                    if stage > 1 {
                        RichTextView(markdown: "**Model plan**\n\n\(problem.plan)")
                    }
                }
            }
            if stage >= 2 {
                Section("3. Code it") {
                    VStack(spacing: 8) {
                        Text("Your solution")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                        CodeEditorField(source: $code, isDisabled: stage > 2)
                    }
                }
                CodeRunSection(problem: problem.implementation, source: code, result: $codeResult)
            }
            if stage >= 3 {
                Section("4. Complexity") {
                    AnswerField(title: "Time complexity", placeholder: "e.g. O(n log n)", text: $input.time, style: .short, isDisabled: stage > 3)
                    AnswerField(title: "Space complexity", placeholder: "e.g. O(1)", text: $input.space, style: .short, isDisabled: stage > 3)
                    if stage > 3 {
                        ComplexityCheckView(expected: .init(code: "", time: problem.time, space: problem.space, explanation: ""), input: input)
                    }
                }
            }
            if stage >= 4 {
                Section("Answer") {
                    RichTextView(markdown: problem.revealMarkdown)
                }
                ExplanationSection(concept: concept, startsExpanded: mode == .learnNew)
                Section {
                    GradeButtonsView(suggested: suggestedGrade, onGrade: grade)
                }
            } else {
                Section {
                    PrimaryActionButtons(
                        primaryTitle: stage == 3 ? "Check Answer" : "Next Stage",
                        isPrimaryDisabled: stage == 0 && problem.options != nil && input.selectedOption == nil,
                        primary: advance
                    )
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { code = code.isEmpty ? StarterCode.withoutImports(problem.starterCode) : code }
    }

    private var suggestedGrade: Grade {
        let patternCorrect: Bool? = problem.correctIndex.map { $0 == input.selectedOption }
        let complexityCorrect = [(input.time, problem.time), (input.space, problem.space)].count { BigONormalizer.areEquivalent($0, $1) }
        return FullProblemGrader.suggest(patternCorrect: patternCorrect, testsPassed: codeResult?.allPassed ?? false, complexityCorrect: complexityCorrect)
    }

    private func advance() {
        stage += 1
    }

    private func grade(_ grade: Grade) {
        onGrade(grade, nil, Date.now.timeIntervalSince(shownAt))
    }
}
