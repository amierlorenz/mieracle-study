import SwiftUI

/// The bottom bar with a summary of the session and the Start button.
struct StartSessionBar: View {
    let summary: String
    let isEnabled: Bool
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(action: onStart) {
                Label("Start Session", systemImage: "play.fill")
                    .font(.headline)
                    .padding(.horizontal, 28)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(!isEnabled)
            .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
