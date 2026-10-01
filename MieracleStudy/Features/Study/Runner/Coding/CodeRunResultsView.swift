import MieracleKit
import SwiftUI

struct CodeRunResultsView: View {
    let result: CodeRunResult

    var body: some View {
        if result.timedOut {
            Label("Timed out. Check for an infinite loop or a very slow approach.", systemImage: "clock.badge.exclamationmark")
                .foregroundStyle(.orange)
        } else if let setupError = result.setupError {
            Label("Your code didn't load", systemImage: "xmark.octagon.fill")
                .foregroundStyle(.red)
            Text(setupError)
                .font(.callout.monospaced())
                .textSelection(.enabled)
        } else {
            Label("\(result.passedCount) of \(result.tests.count) tests passed", systemImage: result.allPassed ? "checkmark.seal.fill" : "xmark.seal")
                .foregroundStyle(result.allPassed ? .green : .red)
            ForEach(result.tests.indices, id: \.self) { index in
                CodeTestResultRow(number: index + 1, test: result.tests[index])
            }
        }
        if !result.stderr.isEmpty, result.setupError == nil {
            Text(result.stderr)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
    }
}
