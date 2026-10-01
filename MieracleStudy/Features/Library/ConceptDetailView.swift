import MieracleKit
import SwiftData
import SwiftUI

struct ConceptDetailView: View {
    let concept: Concept

    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var newPromptKind: PromptKind?
    @State private var editingPrompt: Prompt?

    var body: some View {
        Form {
            Section("Explanation") {
                if concept.explanation.isEmpty {
                    Text("No explanation")
                        .foregroundStyle(.secondary)
                } else {
                    RichTextView(markdown: concept.explanation)
                }
            }
            if !concept.resources.isEmpty {
                Section("Resources") {
                    ForEach(concept.resources, id: \.self) { resource in
                        Link(resource.title, destination: resource.url)
                    }
                }
            }
            if let tags = concept.tags, !tags.isEmpty {
                Section("Tags") {
                    Text(tags.map(\.name).sorted().joined(separator: ", "))
                }
            }
            ConceptScheduleSection(concept: concept)
            Section("Prompts") {
                ForEach(sortedPrompts) { prompt in
                    PromptRow(prompt: prompt)
                        .contentShape(.rect)
                        .onTapGesture { editingPrompt = prompt }
                        .contextMenu {
                            Button("Edit", systemImage: "pencil") { editingPrompt = prompt }
                            Button(prompt.isFlagged ? "Unflag" : "Flag", systemImage: "flag") { toggleFlag(prompt) }
                            Button("Delete", systemImage: "trash", role: .destructive) { delete(prompt) }
                        }
                }
                .onDelete(perform: deletePrompts)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(concept.title)
        .toolbar {
            Button("Edit Concept", systemImage: "pencil") { isEditing = true }
            Menu("Add Prompt", systemImage: "plus") {
                ForEach(PromptKind.allCases, id: \.self) { kind in
                    Button(kind.displayName) { newPromptKind = kind }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            ConceptEditorSheet(title: "Edit Concept", draft: ConceptDraft(concept: concept), onSave: update)
        }
        .sheet(item: $newPromptKind) { kind in
            PromptEditorSheet(title: "New Prompt", draft: PromptDraft(kind: kind), onSave: addPrompt)
        }
        .sheet(item: $editingPrompt) { prompt in
            PromptEditorSheet(title: "Edit Prompt", draft: PromptDraft(prompt: prompt)) { content in
                update(prompt, content: content)
            }
        }
    }

    private var sortedPrompts: [Prompt] {
        (concept.prompts ?? []).sorted { $0.createdAt < $1.createdAt }
    }

    private func update(from draft: ConceptDraft) {
        draft.apply(to: concept, in: modelContext)
        modelContext.saveLogging()
    }

    private func addPrompt(_ content: PromptContent) {
        let prompt = Prompt(content: content)
        prompt.concept = concept
        modelContext.saveLogging()
    }

    private func update(_ prompt: Prompt, content: PromptContent) {
        prompt.content = content
        modelContext.saveLogging()
    }

    private func toggleFlag(_ prompt: Prompt) {
        prompt.isFlagged.toggle()
        modelContext.saveLogging()
    }

    private func delete(_ prompt: Prompt) {
        modelContext.delete(prompt)
        modelContext.saveLogging()
    }

    private func deletePrompts(at offsets: IndexSet) {
        let prompts = sortedPrompts
        offsets.map { prompts[$0] }.forEach(modelContext.delete)
        modelContext.saveLogging()
    }
}
