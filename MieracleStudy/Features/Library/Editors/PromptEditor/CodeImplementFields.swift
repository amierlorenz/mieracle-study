import MieracleKit
import SwiftUI

struct CodeImplementFields: View {
    @Binding var draft: PromptDraft

    var body: some View {
        Section("Problem statement") {
            TextField("Statement", text: $draft.prompt, axis: .vertical).lineLimit(4...)
        }
        Section("Function") {
            Picker("Language", selection: $draft.language) {
                Text("Python").tag(CodeLanguage.python)
                Text("Swift").tag(CodeLanguage.swift)
            }
            TextField("Function name", text: $draft.functionName)
                .monospaced()
            if draft.language == .swift {
                TextField("Parameter types, separated by ;", text: $draft.parameterTypes, prompt: Text(verbatim: "[Int]; Int"))
                    .monospaced()
                TextField("Return type", text: $draft.returnType, prompt: Text(verbatim: "[Int]"))
                    .monospaced()
            }
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
