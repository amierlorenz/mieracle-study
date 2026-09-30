import MieracleKit
import SwiftUI

struct PromptEditorSheet: View {
    let title: String
    let onSave: (PromptContent) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: PromptDraft
    @State private var errorMessage: String?

    init(title: String, draft: PromptDraft, onSave: @escaping (PromptContent) -> Void) {
        self.title = title
        self.onSave = onSave
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Kind", selection: $draft.kind) {
                    ForEach(PromptKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                PromptFieldsView(draft: $draft)
            }
            .formStyle(.grouped)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .alert("Can't Save Prompt", isPresented: isShowingError) {
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .sheetFrame()
    }

    private var isShowingError: Binding<Bool> {
        Binding { errorMessage != nil } set: { if !$0 { errorMessage = nil } }
    }

    private func save() {
        do {
            onSave(try draft.content())
            dismiss()
        } catch {
            errorMessage = error.message
        }
    }
}
