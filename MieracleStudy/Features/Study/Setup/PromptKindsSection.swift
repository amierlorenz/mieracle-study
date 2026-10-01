import MieracleKit
import SwiftUI

struct PromptKindsSection: View {
    @Binding var kinds: Set<PromptKind>
    /// Kinds that have at least one prompt in the selected scope.
    let kindsInScope: Set<PromptKind>

    var body: some View {
        Section {
            ForEach(platformKinds) { kind in
                Toggle(kind.displayName, isOn: binding(for: kind))
                    .disabled(!kindsInScope.contains(kind))
            }
        } header: {
            Text("Prompt types")
        } footer: {
            Text("Types with no prompts in the selected classes and units are unavailable.")
        }
    }

    private var platformKinds: [PromptKind] {
        #if os(macOS)
        PromptKind.allCases
        #else
        PromptKind.allCases.filter { !$0.requiresCodeRunner }
        #endif
    }

    private func binding(for kind: PromptKind) -> Binding<Bool> {
        Binding {
            kinds.contains(kind)
        } set: { isOn in
            if isOn { kinds.insert(kind) } else { kinds.remove(kind) }
        }
    }
}
