import SwiftUI

struct CodeComplexityFields: View {
    @Binding var draft: PromptDraft

    var body: some View {
        Section("Code") {
            TextField("Code", text: $draft.prompt, axis: .vertical)
                .lineLimit(4...)
                .monospaced()
        }
        Section("Answer") {
            TextField("Time, e.g. O(n log n)", text: $draft.time)
            TextField("Space, e.g. O(1)", text: $draft.space)
        }
        Section("Explanation") {
            TextField("Explanation", text: $draft.explanation, axis: .vertical).lineLimit(2...)
        }
    }
}
