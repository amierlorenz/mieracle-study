import SwiftUI

struct UnitEditorSheet: View {
    let title: String
    let onSave: (String, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var sortIndex: Int

    init(title: String, name: String = "", sortIndex: Int, onSave: @escaping (String, Int) -> Void) {
        self.title = title
        self.onSave = onSave
        _name = State(initialValue: name)
        _sortIndex = State(initialValue: sortIndex)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Order", value: $sortIndex, format: .number)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
            }
            .formStyle(.grouped)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 200)
        #endif
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private func save() {
        onSave(trimmedName, sortIndex)
        dismiss()
    }
}
