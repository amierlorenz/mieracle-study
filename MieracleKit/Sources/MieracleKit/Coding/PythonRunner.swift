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
        try Self.harness().write(to: directory.appending(path: "harness.py"))
        let config: [String: Any] = [
            "functionName": problem.functionName,
            "comparison": problem.comparison.rawValue,
            "tests": try problem.tests.map { try JSONSerialization.jsonObject(with: JSONEncoder().encode(TestPayload($0)), options: .fragmentsAllowed) },
        ]
        try JSONSerialization.data(withJSONObject: config).write(to: directory.appending(path: "tests.json"))

        let (stdout, stderr, timedOut) = try await execute(in: directory)
        var result = CodeRunResult(timedOut: timedOut, stderr: stderr)
        guard !timedOut else { return result }
        guard let line = stdout.split(separator: "\n").last(where: { $0.hasPrefix(Self.marker) }) else {
            throw RunnerError.unreadableOutput(stderr.isEmpty ? stdout : stderr)
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

    private static func harness() throws -> Data {
        guard let url = Bundle.module.url(forResource: "harness", withExtension: "py") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }

    #if os(macOS)
    private func execute(in directory: URL) async throws -> (stdout: String, stderr: String, timedOut: Bool) {
        let stdoutURL = directory.appending(path: "stdout.txt")
        let stderrURL = directory.appending(path: "stderr.txt")
        FileManager.default.createFile(atPath: stdoutURL.path(), contents: nil)
        FileManager.default.createFile(atPath: stderrURL.path(), contents: nil)
        let stdoutHandle = try FileHandle(forWritingTo: stdoutURL)
        let stderrHandle = try FileHandle(forWritingTo: stderrURL)
        defer {
            try? stdoutHandle.close()
            try? stderrHandle.close()
        }

        let process = Process()
        process.executableURL = URL(filePath: pythonPath)
        process.arguments = ["-I", "harness.py"]
        process.currentDirectoryURL = directory
        process.environment = ["PYTHONDONTWRITEBYTECODE": "1", "PYTHONIOENCODING": "utf-8", "PATH": "/usr/bin:/bin"]
        process.standardOutput = stdoutHandle
        process.standardError = stderrHandle
        process.standardInput = FileHandle.nullDevice

        let timedOut = try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                    process.terminationHandler = { _ in continuation.resume() }
                    do {
                        try process.run()
                    } catch {
                        process.terminationHandler = nil
                        continuation.resume(throwing: error)
                    }
                }
                return false
            }
            group.addTask { [timeout] in
                try await Task.sleep(for: timeout)
                return true
            }
            let first = try await group.next() ?? false
            if first {
                process.terminate()
                try? await Task.sleep(for: .milliseconds(300))
                if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            }
            group.cancelAll()
            return first
        }

        let stdout = (try? String(contentsOf: stdoutURL, encoding: .utf8)) ?? ""
        let stderr = (try? String(contentsOf: stderrURL, encoding: .utf8)) ?? ""
        return (stdout, stderr, timedOut)
    }
    #endif
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
