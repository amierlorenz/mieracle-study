import MieracleKit
import SwiftUI

/// A capsule toggle for units and tags.
struct SelectableChip: View {
    let title: String
    let state: SelectionState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: state == .all ? "checkmark" : state == .some ? "minus" : "plus")
                .font(.callout)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .glassEffect(state == .none ? .regular.interactive() : .regular.tint(.accentColor.opacity(0.2)).interactive(), in: .capsule)
    }
}
