import MieracleKit
import SwiftUI

struct ConceptEditorSheet: View {
    let title: String
    let onSave: (ConceptDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: ConceptDraft

    init(title: String, draft: ConceptDraft, onSave: @escaping (ConceptDraft) -> Void) {
        self.title = title
        self.onSave = onSave
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $draft.title)
                Section("Explanation (Markdown, $LaTeX$)") {
                    TextField("Explanation", text: $draft.explanation, axis: .vertical)
                        .lineLimit(6...)
                }
                if !draft.explanation.isEmpty {
                    Section("Preview") {
                        RichTextView(markdown: draft.explanation)
                    }
                }
                Section("Tags (comma separated)") {
                    TextField("exam2, recursion", text: $draft.tagsText)
                }
                Section("Resources (one per line: Title | URL)") {
                    TextField("Resources", text: $draft.resourcesText, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!draft.isValid)
                }
            }
        }
        .sheetFrame()
    }

    private func save() {
        onSave(draft)
        dismiss()
    }
}
