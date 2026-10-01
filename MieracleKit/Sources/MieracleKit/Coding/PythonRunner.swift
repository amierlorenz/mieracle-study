import Foundation

/// Runs Python solutions with a local `python3`, isolated in a temporary
/// directory and stopped after a timeout. macOS only: iOS can't launch processes.
public struct PythonRunner: CodeRunner {
    public static let candidatePaths = ["/opt/homebrew/bin/python3", "/usr/local/bin/python3", "/usr/bin/python3"]

    public var pythonPath: String
    public var timeout: Duration

    public init(pythonPath: String, timeout: Duration = .seconds(5)) {
        self.pythonPath = pythonPath
        self.timeout = timeout
    }

    /// The first installed interpreter among ``candidatePaths``.
    public static var detectedPythonPath: String? {
        candidatePaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    public enum RunnerError: Error, Equatable {
        case pythonNotFound(String)
        case unsupportedPlatform
        case unreadableOutput(String)
    }

    public func run(source: String, problem: PromptContent.CodeImplement) async throws -> CodeRunResult {
        #if os(macOS)
        guard FileManager.default.isExecutableFile(atPath: pythonPath) else {
            throw RunnerError.pythonNotFound(pythonPath)
        }
        let directory = FileManager.default.temporaryDirectory.appending(path: "mieracle-run-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try Data(source.utf8).write(to: directory.appending(path: "solution.py"))
        try Data(PythonHarness.source.utf8).write(to: directory.appending(path: "harness.py"))
        let config: [String: Any] = [
            "functionName": problem.functionName,
            "comparison": problem.comparison.rawValue,
            "tests": try problem.tests.map { try JSONSerialization.jsonObject(with: JSONEncoder().encode(TestPayload($0)), options: .fragmentsAllowed) },
        ]
        try JSONSerialization.data(withJSONObject: config).write(to: directory.appending(path: "tests.json"))

        let run = try await ProcessRunner.run(
            pythonPath, ["-I", "harness.py"], in: directory, timeout: timeout,
            environment: ["PYTHONDONTWRITEBYTECODE": "1", "PYTHONIOENCODING": "utf-8", "PATH": "/usr/bin:/bin"]
        )
        var result = CodeRunResult(timedOut: run.timedOut, stderr: run.stderr)
        guard !run.timedOut else { return result }
        guard let line = run.stdout.split(separator: "\n").last(where: { $0.hasPrefix(Self.marker) }) else {
            throw RunnerError.unreadableOutput(run.stderr.isEmpty ? run.stdout : run.stderr)
        }
        let output = try JSONDecoder().decode(HarnessOutput.self, from: Data(line.dropFirst(Self.marker.count).utf8))
        result.setupError = output.setupError
        result.tests = zip(problem.tests, output.results ?? []).map { test, outcome in
            CodeRunResult.Test(
                passed: outcome.passed,
                args: test.args,
                expected: test.expected,
                actual: outcome.actual,
                error: outcome.error,
                stdout: outcome.stdout ?? "",
                isHidden: test.isHidden
            )
        }
        return result
        #else
        throw RunnerError.unsupportedPlatform
        #endif
    }

    private static let marker = "__MIERACLE_RESULT__"

}

private struct TestPayload: Encodable {
    let args: [JSONValue]
    let expected: JSONValue

    init(_ test: CodeTestCase) {
        args = test.args
        expected = test.expected
    }
}

private struct HarnessOutput: Decodable {
    struct Outcome: Decodable {
        let passed: Bool
        let actual: JSONValue?
        let error: String?
        let stdout: String?
    }

    let setupError: String?
    let results: [Outcome]?
}
