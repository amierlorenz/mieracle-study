import SwiftUI

struct ShortAnswerFields: View {
    @Binding var draft: PromptDraft

    var body: some View {
        Section("Question") {
            TextField("Question", text: $draft.prompt, axis: .vertical).lineLimit(2...)
        }
        Section("Model answer") {
            TextField("Model answer", text: $draft.answer, axis: .vertical).lineLimit(3...)
        }
        Section("Key points (one per line)") {
            TextField("Key points", text: $draft.listText, axis: .vertical).lineLimit(3...)
        }
    }
}
