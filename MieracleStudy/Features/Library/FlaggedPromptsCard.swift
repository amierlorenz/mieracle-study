import MieracleKit
import SwiftData
import SwiftUI

/// Prompts flagged during study, listed first so they get reviewed.
struct FlaggedPromptsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Prompt> { $0.isFlagged }, sort: \Prompt.createdAt) private var flagged: [Prompt]

    var body: some View {
        if !flagged.isEmpty {
            Section {
                ForEach(flagged) { prompt in
                    if let concept = prompt.concept {
                        NavigationLink(value: concept) {
                            VStack(alignment: .leading) {
                                PromptRow(prompt: prompt)
                                Text(concept.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contextMenu {
                            Button("Unflag", systemImage: "flag.slash") { unflag(prompt) }
                            Button("Delete", systemImage: "trash", role: .destructive) { delete(prompt) }
                        }
                    }
                }
            } header: {
                Label("Flagged prompts (\(flagged.count))", systemImage: "flag.fill")
                    .foregroundStyle(.orange)
            } footer: {
                Text("Flagged prompts are skipped in sessions. Fix, unflag, or delete them.")
            }
        }
    }

    private func unflag(_ prompt: Prompt) {
        prompt.isFlagged = false
        modelContext.saveLogging()
    }

    private func delete(_ prompt: Prompt) {
        modelContext.delete(prompt)
        modelContext.saveLogging()
    }
}
