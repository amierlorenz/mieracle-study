import SwiftUI

struct FlashcardFields: View {
    @Binding var draft: PromptDraft

    var body: some View {
        Section("Front") {
            TextField("Front", text: $draft.prompt, axis: .vertical).lineLimit(3...)
        }
        Section("Back") {
            TextField("Back", text: $draft.answer, axis: .vertical).lineLimit(3...)
        }
    }
}
