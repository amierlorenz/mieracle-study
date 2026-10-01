import SwiftUI

/// A monospaced editor for solutions, styled like the other answer fields.
struct CodeEditorField: View {
    @Binding var source: String
    let isDisabled: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        TextEditor(text: $source)
            .font(.body.monospaced())
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .scrollContentBackground(.hidden)
            .focused($isFocused)
            .frame(minHeight: 220)
            .padding(8)
            .background(.background, in: .rect(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isFocused ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: isFocused ? 2 : 1)
            }
            .disabled(isDisabled)
    }
}
