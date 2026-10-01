import Foundation
import MieracleKit
import Testing

@Suite(.enabled(if: SwiftRunner.isAvailable, "Swift toolchain not installed"), .timeLimit(.minutes(3)))
struct SwiftRunnerTests {
    let runner = SwiftRunner(testTimeout: .seconds(3))

    func problem(_ tests: [CodeTestCase], comparison: OutputComparison = .exact) -> PromptContent.CodeImplement {
        .init(
            statement: "",
            language: .swift,
            functionName: "twoSum",
            starterCode: "",
            tests: tests,
            comparison: comparison,
            signature: .init(parameters: ["[Int]", "Int"], returns: "[Int]")
        )
    }

    let tests: [CodeTestCase] = [
        .init(args: [.array([.number(2), .number(7), .number(11)]), .number(9)], expected: .array([.number(0), .number(1)])),
        .init(args: [.array([.number(3), .number(3)]), .number(6)], expected: .array([.number(0), .number(1)]), isHidden: true),
    ]

    let solution = """
    func twoSum(_ nums: [Int], _ target: Int) -> [Int] {
        var seen: [Int: Int] = [:]
        for (i, n) in nums.enumerated() {
            if let j = seen[target - n] { return [j, i] }
            seen[n] = i
        }
        return []
    }
    """

    @Test func passingSolutionAndPrints() async throws {
        let source = solution.replacingOccurrences(of: "var seen", with: "print(\"hi #\\\"\")\n    var seen")
        let result = try await runner.run(source: source, problem: problem(tests))
        #expect(result.allPassed)
        #expect(result.tests.first?.stdout == "hi #\"")
    }

    @Test func wrongAnswerAndUnorderedComparison() async throws {
        let reversed = solution.replacingOccurrences(of: "return [j, i]", with: "return [i, j]")
        #expect(try await runner.run(source: reversed, problem: problem(tests)).passedCount == 0)
        #expect(try await runner.run(source: reversed, problem: problem(tests, comparison: .unordered)).allPassed)
    }

    @Test func compileErrorIsSetupError() async throws {
        let result = try await runner.run(source: "func twoSum(_ nums: [Int], _ target: Int) -> [Int] { return nope }", problem: problem(tests))
        #expect(result.setupError?.contains("nope") == true)
    }

    @Test func crashFailsOnlyThatTest() async throws {
        let source = """
        func twoSum(_ nums: [Int], _ target: Int) -> [Int] {
            if nums.count == 2 { return [nums[5]] }
            return [0, 1]
        }
        """
        let result = try await runner.run(source: source, problem: problem(tests))
        #expect(result.tests[0].passed)
        #expect(result.tests[1].error?.hasPrefix("Crashed") == true)
    }

    @Test func infiniteLoopTimesOut() async throws {
        let source = "func twoSum(_ nums: [Int], _ target: Int) -> [Int] { while true {} }"
        let result = try await runner.run(source: source, problem: problem(Array(tests.prefix(1))))
        #expect(result.timedOut)
        #expect(result.tests.first?.error == "Timed out.")
    }
}

struct JSONComparisonTests {
    @Test func comparesWithModes() {
        let expected = JSONValue.array([.number(1), .number(2)])
        #expect(expected.matches(.array([.number(1), .number(2)]), comparison: .exact))
        #expect(!expected.matches(.array([.number(2), .number(1)]), comparison: .exact))
        #expect(expected.matches(.array([.number(2), .number(1)]), comparison: .unordered))
        #expect(JSONValue.number(0.3333333).matches(.number(1.0 / 3.0), comparison: .float))
        #expect(!JSONValue.number(0.33).matches(.number(1.0 / 3.0), comparison: .float))
    }
}
