import SwiftUI

/// A clearly marked place to type an answer: a centered heading above a
/// bordered field that highlights while focused.
struct AnswerField: View {
    enum Style {
        /// Multi-line prose with spell check.
        case prose
        /// One short line, such as a Big-O expression.
        case short
    }

    let title: String
    let placeholder: String
    @Binding var text: String
    var style = Style.prose
    var isDisabled = false

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
            field
                .focused($isFocused)
                .disabled(isDisabled)
                .padding(10)
                .background(.background, in: .rect(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isFocused ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: isFocused ? 2 : 1)
                }
                .opacity(isDisabled ? 0.7 : 1)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var field: some View {
        switch style {
        case .short:
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .monospaced()
                .autocorrectionDisabled()
        case .prose:
            #if os(macOS)
            SpellCheckingTextView(text: $text, placeholder: placeholder)
                .frame(minHeight: 70)
            #else
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(3...)
                .textFieldStyle(.plain)
            #endif
        }
    }
}
