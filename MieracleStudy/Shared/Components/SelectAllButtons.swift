import SwiftUI

/// Select All and Deselect All, each shown only when it would change something.
struct SelectAllButtons: View {
    let canSelectAll: Bool
    let canDeselectAll: Bool
    let selectAll: () -> Void
    let deselectAll: () -> Void

    var body: some View {
        if canSelectAll {
            Button("Select All", systemImage: "checkmark.circle") {
                withAnimation(.spring(duration: 0.35), selectAll)
            }
            .transition(.opacity.combined(with: .scale))
        }
        if canDeselectAll {
            Button("Deselect All", systemImage: "circle") {
                withAnimation(.spring(duration: 0.35), deselectAll)
            }
            .transition(.opacity.combined(with: .scale))
        }
    }
}
