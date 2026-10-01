import MieracleKit
import Synchronization

/// Scripted ``AIProvider`` that records calls. `rephrasings` receives the
/// question and the 1-based call number.
final class MockAIProvider: AIProvider {
    let isAvailable: Bool
    let suggestion: GradeSuggestion
    let rephrasings: @Sendable (String, Int) -> [String]
    private let calls = Mutex(0)

    init(
        isAvailable: Bool = true,
        suggestion: GradeSuggestion = .init(grade: .good, feedback: "Nice."),
        rephrasings: @escaping @Sendable (String, Int) -> [String] = { question, call in ["\(question) (variant \(call))"] }
    ) {
        self.isAvailable = isAvailable
        self.suggestion = suggestion
        self.rephrasings = rephrasings
    }

    var callCount: Int { calls.withLock { $0 } }

    func grade(_ request: GradingRequest) async throws -> GradeSuggestion {
        calls.withLock { $0 += 1 }
        return suggestion
    }

    func rephrase(question: String, answer: String, count: Int) async throws -> [String] {
        let call = calls.withLock { $0 += 1; return $0 }
        return rephrasings(question, call)
    }
}
