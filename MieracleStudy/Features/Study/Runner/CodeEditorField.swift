import SwiftUI

/// A plain monospaced editor for solutions.
struct CodeEditorField: View {
    @Binding var source: String
    let isDisabled: Bool

    var body: some View {
        TextEditor(text: $source)
            .font(.body.monospaced())
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .frame(minHeight: 220)
            .disabled(isDisabled)
    }
}
