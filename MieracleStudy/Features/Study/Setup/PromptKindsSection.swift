import MieracleKit
import SwiftUI

struct PromptKindsSection: View {
    @Binding var kinds: Set<PromptKind>

    var body: some View {
        Section("Prompt types") {
            ForEach(availableKinds) { kind in
                Toggle(kind.displayName, isOn: binding(for: kind))
            }
        }
    }

    private var availableKinds: [PromptKind] {
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
