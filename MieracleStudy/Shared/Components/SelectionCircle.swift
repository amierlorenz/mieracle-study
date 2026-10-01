import MieracleKit
import SwiftUI

/// The native-style select circle: empty, partly selected, or checked.
struct SelectionCircle: View {
    let state: SelectionState

    var body: some View {
        Image(systemName: symbol)
            .font(.title2)
            .symbolRenderingMode(.palette)
            .foregroundStyle(state == .none ? AnyShapeStyle(.secondary) : AnyShapeStyle(.white), state == .none ? AnyShapeStyle(.clear) : AnyShapeStyle(Color.accentColor))
            .accessibilityLabel(label)
    }

    private var symbol: String {
        switch state {
        case .none: "circle"
        case .some: "minus.circle.fill"
        case .all: "checkmark.circle.fill"
        }
    }

    private var label: String {
        switch state {
        case .none: "Not selected"
        case .some: "Partly selected"
        case .all: "Selected"
        }
    }
}
