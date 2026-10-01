import Foundation
import MieracleKit
import Testing

@Suite(.enabled(if: PythonRunner.detectedPythonPath != nil, "python3 not installed"))
struct PythonRunnerTests {
    let runner = PythonRunner(pythonPath: PythonRunner.detectedPythonPath ?? "", timeout: .seconds(2))

    func problem(_ name: String = "add", tests: [CodeTestCase], comparison: OutputComparison = .exact) -> PromptContent.CodeImplement {
        .init(statement: "", functionName: name, starterCode: "", tests: tests, comparison: comparison)
    }

    let addTests: [CodeTestCase] = [
        .init(args: [.number(1), .number(2)], expected: .number(3)),
        .init(args: [.number(-1), .number(1)], expected: .number(0), isHidden: true),
    ]

    @Test func passingSolution() async throws {
        let result = try await runner.run(source: "def add(a, b):\n    return a + b\n", problem: problem(tests: addTests))
        #expect(result.allPassed)
        #expect(result.passedCount == 2)
        #expect(result.tests[1].isHidden)
        #expect(result.suggestedGrade == .good)
    }

    @Test func failingSolutionReportsActual() async throws {
        let result = try await runner.run(source: "def add(a, b):\n    return a - b\n", problem: problem(tests: addTests))
        #expect(!result.allPassed)
        #expect(result.tests[0].actual == .number(-1))
        #expect(result.suggestedGrade == .again)
    }

    @Test func exceptionIsReportedPerTest() async throws {
        let result = try await runner.run(source: "def add(a, b):\n    return a / 0\n", problem: problem(tests: addTests))
        #expect(result.tests.allSatisfy { $0.error?.contains("ZeroDivisionError") == true })
    }

    @Test func syntaxErrorIsSetupError() async throws {
        let result = try await runner.run(source: "def add(a, b)\n    return a + b\n", problem: problem(tests: addTests))
        #expect(result.setupError?.contains("SyntaxError") == true)
        #expect(result.tests.isEmpty)
        #expect(!result.allPassed)
    }

    @Test func missingFunctionIsSetupError() async throws {
        let result = try await runner.run(source: "def plus(a, b):\n    return a + b\n", problem: problem(tests: addTests))
        #expect(result.setupError?.contains("No function named 'add'") == true)
    }

    @Test(.timeLimit(.minutes(1)))
    func infiniteLoopTimesOut() async throws {
        let result = try await runner.run(source: "def add(a, b):\n    while True:\n        pass\n", problem: problem(tests: addTests))
        #expect(result.timedOut)
        #expect(!result.allPassed)
    }

    @Test func leetCodeStyleSolutionClass() async throws {
        let source = "class Solution:\n    def add(self, a, b):\n        return a + b\n"
        #expect(try await runner.run(source: source, problem: problem(tests: addTests)).allPassed)
    }

    @Test func unorderedAndFloatComparisons() async throws {
        let unordered = problem("pairs", tests: [.init(args: [], expected: .array([.number(1), .number(2), .number(3)]))], comparison: .unordered)
        #expect(try await runner.run(source: "def pairs():\n    return {3, 1, 2}\n", problem: unordered).allPassed)

        let float = problem("third", tests: [.init(args: [], expected: .number(0.3333333))], comparison: .float)
        #expect(try await runner.run(source: "def third():\n    return 1 / 3\n", problem: float).allPassed)
    }

    @Test func capturesPrintsWithoutBreakingOutput() async throws {
        let source = "print('loading')\ndef add(a, b):\n    print('debug', a, b)\n    return a + b\n"
        let result = try await runner.run(source: source, problem: problem(tests: addTests))
        #expect(result.allPassed)
        #expect(result.tests[0].stdout == "debug 1 2\n")
    }

    @Test func argumentsAreNotSharedBetweenTests() async throws {
        let tests: [CodeTestCase] = [
            .init(args: [.array([.number(1)])], expected: .array([.number(1), .number(0)])),
            .init(args: [.array([.number(1)])], expected: .array([.number(1), .number(0)])),
        ]
        let source = "def grow(xs):\n    xs.append(0)\n    return xs\n"
        #expect(try await runner.run(source: source, problem: problem("grow", tests: tests)).allPassed)
    }

    @Test func missingInterpreterThrows() async throws {
        await #expect(throws: PythonRunner.RunnerError.pythonNotFound("/nope/python3")) {
            try await PythonRunner(pythonPath: "/nope/python3").run(source: "", problem: problem(tests: addTests))
        }
    }
}
