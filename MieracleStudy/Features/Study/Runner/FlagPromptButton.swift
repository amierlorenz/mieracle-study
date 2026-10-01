import MieracleKit
import SwiftData
import SwiftUI

/// Marks a bad or confusing prompt so sessions stop showing it.
struct FlagPromptButton: View {
    let prompt: Prompt

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if prompt.isFlagged {
            Label("Flagged. It won't be shown again; review it in the Library.", systemImage: "flag.fill")
                .foregroundStyle(.orange)
        } else {
            Button("Flag this prompt", systemImage: "flag", action: flag)
                .buttonStyle(.borderless)
        }
    }

    private func flag() {
        prompt.isFlagged = true
        modelContext.saveLogging()
    }
}
