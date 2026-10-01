import Foundation

/// Compiles Swift solutions with `swiftc` and runs each test in its own
/// process, so a crash fails one test instead of the whole run. macOS only.
public struct SwiftRunner: CodeRunner {
    public static let xcrunPath = "/usr/bin/xcrun"

    public var compileTimeout: Duration
    public var testTimeout: Duration

    public init(compileTimeout: Duration = .seconds(90), testTimeout: Duration = .seconds(5)) {
        self.compileTimeout = compileTimeout
        self.testTimeout = testTimeout
    }

    public static var isAvailable: Bool {
        FileManager.default.isExecutableFile(atPath: xcrunPath)
    }

    public enum RunnerError: Error, Equatable {
        case missingSignature
        case toolchainNotFound
        case unsupportedPlatform
    }

    public func run(source: String, problem: PromptContent.CodeImplement) async throws -> CodeRunResult {
        #if os(macOS)
        guard let signature = problem.signature else { throw RunnerError.missingSignature }
        guard Self.isAvailable else { throw RunnerError.toolchainNotFound }
        let directory = FileManager.default.temporaryDirectory.appending(path: "mieracle-swift-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try Data(Self.program(source: source, problem: problem, signature: signature).utf8).write(to: directory.appending(path: "main.swift"))
        let compile = try await ProcessRunner.run(
            Self.xcrunPath, ["swiftc", "-O", "-suppress-warnings", "main.swift", "-o", "solution"],
            in: directory, timeout: compileTimeout
        )
        var result = CodeRunResult()
        if compile.timedOut {
            result.setupError = "Compiling took too long."
            return result
        }
        guard compile.status == 0 else {
            result.setupError = Self.cleaned(compile.stderr, directory: directory)
            return result
        }

        for (index, test) in problem.tests.enumerated() {
            let run = try await ProcessRunner.run(directory.appending(path: "solution").path(), [String(index)], in: directory, timeout: testTimeout)
            var outcome = CodeRunResult.Test(passed: false, args: test.args, expected: test.expected, actual: nil, error: nil, stdout: "", isHidden: test.isHidden)
            let lines = run.stdout.split(separator: "\n", omittingEmptySubsequences: false)
            outcome.stdout = lines.filter { !$0.hasPrefix(Self.marker) }.joined(separator: "\n").trimmingCharacters(in: .newlines)
            if run.timedOut {
                outcome.error = "Timed out."
                result.timedOut = true
            } else if let line = lines.last(where: { $0.hasPrefix(Self.marker) }),
                      let actual = try? JSONDecoder().decode(JSONValue.self, from: Data(line.dropFirst(Self.marker.count).utf8)) {
                outcome.actual = actual
                outcome.passed = test.expected.matches(actual, comparison: problem.comparison)
            } else {
                outcome.error = run.status == 0 ? "No result printed." : "Crashed (\(Self.cleaned(run.stderr, directory: directory).split(separator: "\n").first ?? "exit \(run.status)"))."
            }
            result.tests.append(outcome)
        }
        return result
        #else
        throw RunnerError.unsupportedPlatform
        #endif
    }

    static let marker = "__MIERACLE_RESULT__"

    /// The learner's code followed by a `main` that decodes test `N`'s
    /// arguments with the signature's types, calls the function, and prints
    /// the JSON result after a marker.
    static func program(source: String, problem: PromptContent.CodeImplement, signature: FunctionSignature) -> String {
        let cases = problem.tests.enumerated().map { index, test in
            let decodes = zip(signature.parameters, test.args).enumerated().map { position, pair in
                "let a\(position) = try! JSONDecoder().decode(\(pair.0).self, from: Data(base64Encoded: \"\(Data(pair.1.compactJSONText.utf8).base64EncodedString())\")!)"
            }
            let call = "\(problem.functionName)(\((0..<signature.parameters.count).map { "a\($0)" }.joined(separator: ", ")))"
            return """
            case \(index):
                \(decodes.joined(separator: "\n    "))
                let result: \(signature.returns) = \(call)
                print("\(marker)" + String(decoding: try! JSONEncoder().encode(result), as: UTF8.self))
            """
        }
        return """
        import Foundation

        \(source)

        switch Int(CommandLine.arguments.dropFirst().first ?? "") ?? -1 {
        \(cases.joined(separator: "\n"))
        default:
            break
        }
        """
    }

    private static func cleaned(_ text: String, directory: URL) -> String {
        text.replacingOccurrences(of: directory.path(), with: "").replacingOccurrences(of: directory.path(percentEncoded: false), with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension JSONValue {
    var compactJSONText: String {
        (try? JSONEncoder().encode(self)).map { String(decoding: $0, as: UTF8.self) } ?? "null"
    }
}
