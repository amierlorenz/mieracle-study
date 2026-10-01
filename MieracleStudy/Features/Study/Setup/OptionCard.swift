import SwiftUI

/// A tappable glass card with an icon, title, and detail; tinted when selected
/// and dimmed when unavailable.
struct OptionCard: View {
    let title: String
    let systemImage: String
    var detail: String?
    let isSelected: Bool
    var isAvailable = true
    let action: () -> Void

    var body: some View {
        Button {
            withAnimation(.spring(duration: 0.35), action)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .frame(height: 28)
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .padding(10)
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        .glassEffect(isSelected ? .regular.tint(.accentColor.opacity(0.16)).interactive() : .regular.interactive(), in: .rect(cornerRadius: 18))
        .scaleEffect(isSelected ? 1.03 : 1)
        .opacity(isAvailable ? 1 : 0.35)
        .animation(.spring(duration: 0.35), value: isSelected)
        .animation(.spring(duration: 0.35), value: isAvailable)
        .disabled(!isAvailable)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
