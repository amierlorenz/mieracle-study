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
            Button(isRunning ? "Running…" : "Run Tests", systemImage: "play.fill") {
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

    private func run() async {
        isRunning = true
        defer { isRunning = false }
        do {
            result = try await PythonRunner(pythonPath: pythonPath).run(source: source, problem: problem)
            errorMessage = nil
        } catch PythonRunner.RunnerError.pythonNotFound(let path) {
            errorMessage = "No python3 at \(path). Set it in Settings → Coding."
        } catch {
            Logger.app.error("Code run failed: \(error)")
            errorMessage = "Couldn't run the code: \(error.localizedDescription)"
        }
    }
}
