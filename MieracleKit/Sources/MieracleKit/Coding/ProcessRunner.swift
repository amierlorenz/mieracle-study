import Foundation

#if os(macOS)
/// Runs a process with a timeout, capturing output through files so large
/// output can't deadlock a pipe.
enum ProcessRunner {
    struct Output {
        var status: Int32
        var stdout: String
        var stderr: String
        var timedOut: Bool
    }

    static func run(_ executable: String, _ arguments: [String], in directory: URL, timeout: Duration, environment: [String: String]? = nil) async throws -> Output {
        let id = UUID().uuidString
        let stdoutURL = directory.appending(path: "stdout-\(id).txt")
        let stderrURL = directory.appending(path: "stderr-\(id).txt")
        FileManager.default.createFile(atPath: stdoutURL.path(), contents: nil)
        FileManager.default.createFile(atPath: stderrURL.path(), contents: nil)
        let stdoutHandle = try FileHandle(forWritingTo: stdoutURL)
        let stderrHandle = try FileHandle(forWritingTo: stderrURL)
        defer {
            try? stdoutHandle.close()
            try? stderrHandle.close()
            try? FileManager.default.removeItem(at: stdoutURL)
            try? FileManager.default.removeItem(at: stderrURL)
        }

        let process = Process()
        process.executableURL = URL(filePath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = directory
        if let environment { process.environment = environment }
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
            group.addTask {
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

        return Output(
            status: process.terminationStatus,
            stdout: (try? String(contentsOf: stdoutURL, encoding: .utf8)) ?? "",
            stderr: (try? String(contentsOf: stderrURL, encoding: .utf8)) ?? "",
            timedOut: timedOut
        )
    }
}
#endif
