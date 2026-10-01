import MieracleKit
import OSLog
import SwiftUI

/// Runs the learner's code against the problem's tests and shows the results.
struct CodeRunSection: View {
    let problem: PromptContent.CodeImplement
    let source: String
    @Binding var result: CodeRunResult?

    @AppStorage(SettingsKey.pythonPath) private var pythonPath = PythonRunner.detectedPythonPath ?? ""
    @State private var isRunning = false
    @State private var errorMessage: String?

    var body: some View {
        Section {
            Button(isRunning ? (problem.language == .swift ? "Compiling and running…" : "Running…") : "Run Tests", systemImage: "play.fill") {
                Task { await run() }
            }
            .disabled(isRunning)
            .keyboardShortcut("r", modifiers: .command)
            if let errorMessage {
                Label(errorMessage, systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
            }
            if let result {
                CodeRunResultsView(result: result)
            }
        } header: {
            Text("Tests")
        } footer: {
            Text("Run as often as you like, then reveal the answer and grade yourself.")
        }
    }

    private var runner: any CodeRunner {
        switch problem.language {
        case .python: PythonRunner(pythonPath: pythonPath)
        case .swift: SwiftRunner()
        }
    }

    private func run() async {
        isRunning = true
        defer { isRunning = false }
        do {
            result = try await runner.run(source: source, problem: problem)
            errorMessage = nil
        } catch PythonRunner.RunnerError.pythonNotFound(let path) {
            errorMessage = "No python3 at \(path). Set it in Settings → Coding."
        } catch SwiftRunner.RunnerError.toolchainNotFound {
            errorMessage = "Swift needs Xcode or the Command Line Tools installed."
        } catch SwiftRunner.RunnerError.missingSignature {
            errorMessage = "This Swift problem has no signature. Add one in the Library."
        } catch {
            Logger.app.error("Code run failed: \(error)")
            errorMessage = "Couldn't run the code: \(error.localizedDescription)"
        }
    }
}
