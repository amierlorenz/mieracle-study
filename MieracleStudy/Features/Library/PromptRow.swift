import MieracleKit
import SwiftUI

struct PromptRow: View {
    let prompt: Prompt

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(prompt.kind.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if prompt.origin == .aiVariant {
                    Text("AI variant")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if prompt.isFlagged {
                    Label("Flagged", systemImage: "flag.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Text(prompt.content?.questionText ?? "Unreadable prompt")
                .lineLimit(3)
        }
    }
}
