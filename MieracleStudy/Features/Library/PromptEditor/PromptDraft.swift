import Foundation
import MieracleKit

/// Editable, kind-agnostic form state for a prompt.
///
/// Fields are shared across kinds (for example ``prompt`` is a flashcard's
/// front, a question, a problem statement, or a code snippet) so switching the
/// kind while editing keeps what was typed.
struct PromptDraft {
    var kind: PromptKind
    var prompt = ""
    var answer = ""
    /// One item per line: key points, or answer options.
    var listText = ""
    var correctIndex = 0
    var explanation = ""
    var functionName = ""
    var starterCode = ""
    var testsJSON = "[\n  {\"args\": [], \"expected\": null}\n]"
    var comparison = OutputComparison.exact
    var referenceSolution = ""
    var time = ""
    var space = ""
    var plan = ""

    init(kind: PromptKind) {
        self.kind = kind
    }

    init(prompt: Prompt) {
        self.init(kind: prompt.kind)
        guard let content = prompt.content else { return }
        switch content {
        case .flashcard(let c):
            self.prompt = c.front
            answer = c.back
        case .shortAnswer(let c):
            self.prompt = c.question
            answer = c.modelAnswer
            listText = c.keyPoints.joined(separator: "\n")
        case .multipleChoice(let c):
            self.prompt = c.question
            listText = c.options.joined(separator: "\n")
            correctIndex = c.correctIndex
            explanation = c.explanation ?? ""
        case .codeImplement(let c):
            self.prompt = c.statement
            functionName = c.functionName
            starterCode = c.starterCode
            testsJSON = Self.encodeTests(c.tests)
            comparison = c.comparison
            referenceSolution = c.referenceSolution ?? ""
            explanation = c.explanation ?? ""
        case .codeComplexity(let c):
            self.prompt = c.code
            time = c.time
            space = c.space
            explanation = c.explanation
        case .patternPick(let c):
            self.prompt = c.statement
            listText = (c.options ?? []).joined(separator: "\n")
            correctIndex = c.correctIndex ?? 0
            answer = c.answer
            explanation = c.explanation
        case .fullProblem(let c):
            self.prompt = c.statement
            listText = (c.options ?? []).joined(separator: "\n")
            correctIndex = c.correctIndex ?? 0
            answer = c.pattern
            plan = c.plan
            functionName = c.functionName
            starterCode = c.starterCode
            testsJSON = Self.encodeTests(c.tests)
            comparison = c.comparison
            referenceSolution = c.referenceSolution ?? ""
            time = c.time
            space = c.space
            explanation = c.explanation
        }
    }

    var listItems: [String] {
        listText.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Builds the content, or throws a message describing what's missing.
    func content() throws(DraftError) -> PromptContent {
        try require(prompt, "The prompt text is empty.")
        switch kind {
        case .flashcard:
            try require(answer, "The back of the card is empty.")
            return .flashcard(.init(front: prompt, back: answer))
        case .shortAnswer:
            try require(answer, "The model answer is empty.")
            return .shortAnswer(.init(question: prompt, modelAnswer: answer, keyPoints: listItems))
        case .multipleChoice:
            let options = listItems
            guard options.count >= 2 else { throw DraftError("Add at least two options.") }
            guard options.indices.contains(correctIndex) else { throw DraftError("Choose the correct option.") }
            return .multipleChoice(.init(question: prompt, options: options, correctIndex: correctIndex, explanation: optional(explanation)))
        case .fullProblem:
            try require(answer, "The pattern is empty.")
            try require(plan, "The plan is empty.")
            try require(functionName, "The function name is empty.")
            try require(time, "The time complexity is empty.")
            try require(space, "The space complexity is empty.")
            let tests = try decodedTests()
            let options = listItems
            if !options.isEmpty, !options.indices.contains(correctIndex) {
                throw DraftError("Choose the correct option.")
            }
            return .fullProblem(.init(
                statement: prompt,
                options: options.isEmpty ? nil : options,
                correctIndex: options.isEmpty ? nil : correctIndex,
                pattern: answer,
                plan: plan,
                functionName: functionName.trimmingCharacters(in: .whitespaces),
                starterCode: starterCode,
                tests: tests,
                comparison: comparison,
                referenceSolution: optional(referenceSolution),
                time: time,
                space: space,
                explanation: explanation
            ))
        case .codeImplement:
            try require(functionName, "The function name is empty.")
            let tests = try decodedTests()
            return .codeImplement(.init(
                statement: prompt,
                functionName: functionName.trimmingCharacters(in: .whitespaces),
                starterCode: starterCode,
                tests: tests,
                comparison: comparison,
                referenceSolution: optional(referenceSolution),
                explanation: optional(explanation)
            ))
        case .codeComplexity:
            try require(time, "The time complexity is empty.")
            try require(space, "The space complexity is empty.")
            return .codeComplexity(.init(code: prompt, time: time, space: space, explanation: explanation))
        case .patternPick:
            try require(answer, "The answer is empty.")
            let options = listItems
            if !options.isEmpty, !options.indices.contains(correctIndex) {
                throw DraftError("Choose the correct option.")
            }
            return .patternPick(.init(
                statement: prompt,
                options: options.isEmpty ? nil : options,
                correctIndex: options.isEmpty ? nil : correctIndex,
                answer: answer,
                explanation: explanation
            ))
        }
    }

    private func decodedTests() throws(DraftError) -> [CodeTestCase] {
        let tests: [CodeTestCase]
        do {
            tests = try JSONDecoder().decode([CodeTestCase].self, from: Data(testsJSON.utf8))
        } catch {
            throw DraftError("Tests must be a JSON array of {\"args\": [...], \"expected\": ...}.")
        }
        guard !tests.isEmpty else { throw DraftError("Add at least one test.") }
        return tests
    }

    private func require(_ text: String, _ message: String) throws(DraftError) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw DraftError(message)
        }
    }

    private func optional(_ text: String) -> String? {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text
    }

    private static func encodeTests(_ tests: [CodeTestCase]) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(tests) else { return "[]" }
        return String(decoding: data, as: UTF8.self)
    }
}
