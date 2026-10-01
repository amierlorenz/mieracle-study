import MieracleKit
import SwiftUI

struct CodeImplementFields: View {
    @Binding var draft: PromptDraft

    var body: some View {
        Section("Problem statement") {
            TextField("Statement", text: $draft.prompt, axis: .vertical).lineLimit(4...)
        }
        Section("Python function") {
            TextField("Function name", text: $draft.functionName)
                .monospaced()
            TextField("Starter code", text: $draft.starterCode, axis: .vertical)
                .lineLimit(4...)
                .monospaced()
        }
        Section("Tests (JSON)") {
            TextField("Tests", text: $draft.testsJSON, axis: .vertical)
                .lineLimit(4...)
                .monospaced()
            Picker("Compare results", selection: $draft.comparison) {
                ForEach(OutputComparison.allCases, id: \.self) { comparison in
                    Text(comparison.rawValue.capitalized).tag(comparison)
                }
            }
        }
        Section("Reference solution") {
            TextField("Reference solution", text: $draft.referenceSolution, axis: .vertical)
                .lineLimit(3...)
                .monospaced()
        }
        Section("Explanation") {
            TextField("Explanation", text: $draft.explanation, axis: .vertical).lineLimit(2...)
        }
    }
}
