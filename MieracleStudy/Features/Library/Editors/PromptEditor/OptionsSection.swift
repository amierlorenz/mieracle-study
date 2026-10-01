import SwiftUI

/// Answer options, one per line, with a picker for the correct one.
struct OptionsSection: View {
    let header: String
    @Binding var draft: PromptDraft

    var body: some View {
        Section(header) {
            TextField("Options", text: $draft.listText, axis: .vertical).lineLimit(3...)
            if !draft.listItems.isEmpty {
                Picker("Correct option", selection: $draft.correctIndex) {
                    ForEach(draft.listItems.indices, id: \.self) { index in
                        Text(draft.listItems[index]).tag(index)
                    }
                }
            }
        }
    }
}
