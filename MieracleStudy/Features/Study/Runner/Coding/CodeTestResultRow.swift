import MieracleKit
import SwiftUI

struct CodeTestResultRow: View {
    let number: Int
    let test: CodeRunResult.Test

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Test \(number)\(test.isHidden ? " (hidden)" : "")", systemImage: test.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(test.passed ? .green : .red)
            if !test.isHidden {
                Group {
                    Text("args: \(test.args.map(\.compactJSON).joined(separator: ", "))")
                    Text("expected: \(test.expected.compactJSON)")
                    if let actual = test.actual {
                        Text("actual: \(actual.compactJSON)")
                    }
                }
                .font(.caption.monospaced())
            }
            if let error = test.error {
                Text(error)
                    .font(.caption.monospaced())
                    .foregroundStyle(.red)
            }
            if !test.stdout.isEmpty {
                Text("printed: \(test.stdout)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .textSelection(.enabled)
    }
}

extension JSONValue {
    var compactJSON: String {
        guard let data = try? JSONEncoder().encode(self) else { return "?" }
        return String(decoding: data, as: UTF8.self)
    }
}
