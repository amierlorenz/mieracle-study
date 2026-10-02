import SwiftUI

/// Blurs its content for a few seconds with a visible countdown, so the
/// learner tries to recall the answer before seeing the choices.
struct CountdownReveal<Content: View>: View {
    let isEnabled: Bool
    var seconds = 5
    @ViewBuilder let content: Content

    @State private var remaining: Int?

    var body: some View {
        content
            .blur(radius: isHidden ? 12 : 0)
            .allowsHitTesting(!isHidden)
            .accessibilityHidden(isHidden)
            .overlay {
                if isHidden, let remaining {
                    Text("Revealing choices in \(remaining)…")
                        .font(.headline)
                        .monospacedDigit()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.regularMaterial, in: .capsule)
                }
            }
            .task(countDown)
    }

    private var isHidden: Bool {
        isEnabled && (remaining ?? seconds) > 0
    }

    private func countDown() async {
        guard isEnabled else { return }
        remaining = seconds
        while let current = remaining, current > 0 {
            try? await Task.sleep(for: .seconds(1))
            remaining = current - 1
        }
    }
}
