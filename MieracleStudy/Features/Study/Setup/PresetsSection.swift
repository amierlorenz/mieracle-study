import MieracleKit
import SwiftData
import SwiftUI

struct PresetsSection: View {
    let current: SessionConfig
    let onLoad: (SessionConfig) -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionPreset.name) private var presets: [SessionPreset]
    @State private var isNaming = false

    var body: some View {
        Section("Presets") {
            ForEach(presets) { preset in
                Button(preset.name) { load(preset) }
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) { delete(preset) }
                    }
            }
            .onDelete(perform: deletePresets)
            Button("Save Current as Preset…", systemImage: "square.and.arrow.down") { isNaming = true }
        }
        .sheet(isPresented: $isNaming) {
            NameEditorSheet(title: "Save Preset", onSave: save)
        }
    }

    private func load(_ preset: SessionPreset) {
        if let config = SessionConfig.decoded(from: preset.configData) {
            onLoad(config)
        }
    }

    private func save(named name: String) {
        modelContext.insert(SessionPreset(name: name, configData: current.encoded()))
        modelContext.saveLogging()
    }

    private func delete(_ preset: SessionPreset) {
        modelContext.delete(preset)
        modelContext.saveLogging()
    }

    private func deletePresets(at offsets: IndexSet) {
        offsets.map { presets[$0] }.forEach(modelContext.delete)
        modelContext.saveLogging()
    }
}
