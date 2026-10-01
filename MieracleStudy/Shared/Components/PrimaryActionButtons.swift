import SwiftUI

/// A centered, prominent Liquid Glass action with an optional smaller
/// secondary action beneath it.
struct PrimaryActionButtons: View {
    let primaryTitle: String
    var isPrimaryDisabled = false
    let primary: () -> Void
    var secondaryTitle: String?
    var secondary: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Button(action: primary) {
                Text(primaryTitle)
                    .font(.headline)
                    .padding(.horizontal, 24)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(isPrimaryDisabled)
            .keyboardShortcut(.return, modifiers: .command)
            if let secondaryTitle, let secondary {
                Button(secondaryTitle, action: secondary)
                    .buttonStyle(.glass)
                    .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}
