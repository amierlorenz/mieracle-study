import MieracleKit
import SwiftUI

/// An optional note on how the session went (*Make It Stick*: reflection).
struct ReflectionSection: View {
    @Bindable var engine: SessionEngine

    var body: some View {
        Section {
            TextField("What was hardest? What would you do differently?", text: $engine.reflection, axis: .vertical)
                .lineLimit(3...)
        } header: {
            Text("Reflection (optional)")
        }
    }
}
