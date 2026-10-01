import FoundationModels
import MieracleKit
import Testing

struct FoundationModelsProviderTests {
    let provider = FoundationModelsProvider()

    @Test func blankAnswerIsAgainWithoutCallingModel() async throws {
        let suggestion = try await provider.grade(.init(question: "Q", modelAnswer: "A", answer: " "))
        #expect(suggestion == .blank)
    }

    @Test(.enabled(if: SystemLanguageModel.default.isAvailable, "Apple Intelligence unavailable"), .timeLimit(.minutes(1)))
    func gradesObviousAnswersSensibly() async throws {
        let base = GradingRequest(
            question: "Why is peeking at the minimum of a min-heap O(1)?",
            modelAnswer: "The heap property keeps the smallest element at the root, so no search is needed.",
            keyPoints: ["minimum is at the root", "no search needed"],
            answer: ""
        )
        var right = base
        right.answer = "Because the smallest item is always kept at the root, you just read it without searching."
        var wrong = base
        wrong.answer = "Because heaps are sorted arrays and you binary search them."

        let good = try await provider.grade(right)
        let bad = try await provider.grade(wrong)

        #expect(good.grade == .good || good.grade == .easy)
        #expect(bad.grade == .again || bad.grade == .hard)
    }

    @Test(.enabled(if: SystemLanguageModel.default.isAvailable, "Apple Intelligence unavailable"), .timeLimit(.minutes(1)))
    func rephrasesWithoutRevealingAnswer() async throws {
        let questions = try await provider.rephrase(question: "Where is the minimum in a min-heap?", answer: "At the root.", count: 2)
        #expect(!questions.isEmpty && questions.count <= 2)
        #expect(questions.allSatisfy { !$0.lowercased().contains("root") })
    }
}

extension FoundationModelsProviderTests {
    @Test(.enabled(if: SystemLanguageModel.default.isAvailable, "Apple Intelligence unavailable"), .timeLimit(.minutes(1)))
    func generatesValidPromptsFromExplanation() async throws {
        let contents = try await provider.generatePrompts(
            title: "Spaced practice",
            explanation: "Spaced practice means studying material several times with time in between, so some forgetting happens first. Reconstructing the idea from memory takes effort, which makes it more durable."
        )
        #expect(contents.map(\.kind) == [.flashcard, .shortAnswer])
        #expect(contents.allSatisfy { !$0.questionText.isEmpty })
    }
}
