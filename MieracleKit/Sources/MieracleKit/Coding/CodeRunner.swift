import Foundation

/// Runs a learner's code against a problem's test cases.
public protocol CodeRunner: Sendable {
    func run(source: String, problem: PromptContent.CodeImplement) async throws -> CodeRunResult
}

public struct CodeRunResult: Equatable, Sendable {
    public struct Test: Equatable, Sendable {
        public var passed: Bool
        public var args: [JSONValue]
        public var expected: JSONValue
        public var actual: JSONValue?
        public var error: String?
        public var stdout: String
        public var isHidden: Bool
    }

    public var tests: [Test] = []
    /// The code failed before any test ran, for example a syntax error.
    public var setupError: String?
    public var timedOut = false
    public var stderr = ""

    public var passedCount: Int { tests.count { $0.passed } }
    public var allPassed: Bool { setupError == nil && !timedOut && !tests.isEmpty && tests.allSatisfy(\.passed) }

    /// All tests passing suggests Good; anything else suggests Again.
    public var suggestedGrade: Grade { allPassed ? .good : .again }
}
