import SwiftUI

/// A brief message with an Undo button that disappears on its own.
struct UndoToast: View {
    let message: String
    let onUndo: () -> Void
    let onExpire: () -> Void
    var seconds: Double = 5

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(message)
                .lineLimit(1)
            Button("Undo", action: onUndo)
                .buttonStyle(.glassProminent)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(in: .capsule)
        .padding(.bottom, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task {
            try? await Task.sleep(for: .seconds(seconds))
            onExpire()
        }
    }
}
