import SwiftUI

struct MultipleChoiceFields: View {
    @Binding var draft: PromptDraft

    var body: some View {
        Section("Question") {
            TextField("Question", text: $draft.prompt, axis: .vertical).lineLimit(2...)
        }
        OptionsSection(header: "Options (one per line)", draft: $draft)
        Section("Explanation") {
            TextField("Explanation", text: $draft.explanation, axis: .vertical).lineLimit(2...)
        }
    }
}
