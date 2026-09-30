import SwiftUI

struct PatternPickFields: View {
    @Binding var draft: PromptDraft

    var body: some View {
        Section("Problem statement") {
            TextField("Statement", text: $draft.prompt, axis: .vertical).lineLimit(4...)
        }
        OptionsSection(header: "Options (optional, one per line)", draft: $draft)
        Section("Answer") {
            TextField("Approach or data structure", text: $draft.answer, axis: .vertical).lineLimit(2...)
        }
        Section("Explanation") {
            TextField("Explanation", text: $draft.explanation, axis: .vertical).lineLimit(2...)
        }
    }
}
