import MieracleKit
import SwiftData
import SwiftUI

/// Prompts flagged during study, shown first so they get reviewed.
struct FlaggedPromptsCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Prompt> { $0.isFlagged }, sort: \Prompt.createdAt) private var flagged: [Prompt]

    var body: some View {
        if !flagged.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Flagged prompts (\(flagged.count))", systemImage: "flag.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Text("Skipped in sessions until you fix, unflag, or delete them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(flagged) { prompt in
                    if let concept = prompt.concept {
                        NavigationLink(value: concept) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    PromptRow(prompt: prompt)
                                    Text(concept.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Unflag", systemImage: "flag.slash") { unflag(prompt) }
                            Button("Delete", systemImage: "trash", role: .destructive) { delete(prompt) }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(.orange.opacity(0.08)), in: .rect(cornerRadius: 22))
        }
    }

    private func unflag(_ prompt: Prompt) {
        withAnimation(.spring(duration: 0.35)) { prompt.isFlagged = false }
        modelContext.saveLogging()
    }

    private func delete(_ prompt: Prompt) {
        withAnimation(.spring(duration: 0.35)) { modelContext.delete(prompt) }
        modelContext.saveLogging()
    }
}
