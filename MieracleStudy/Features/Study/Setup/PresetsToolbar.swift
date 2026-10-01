import MieracleKit
import SwiftData
import SwiftUI

/// Toolbar items for loading, saving, and deleting session presets.
struct PresetsToolbar: ToolbarContent {
    let current: SessionConfig
    let onLoad: (SessionConfig) -> Void
    let onSave: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionPreset.name) private var presets: [SessionPreset]

    var body: some ToolbarContent {
        ToolbarItem {
            Menu("Presets", systemImage: "bookmark") {
                if presets.isEmpty {
                    Text("No presets yet")
                }
                ForEach(presets) { preset in
                    Button(preset.name) { load(preset) }
                }
                if !presets.isEmpty {
                    Divider()
                    Menu("Delete Preset") {
                        ForEach(presets) { preset in
                            Button(preset.name, role: .destructive) { delete(preset) }
                        }
                    }
                }
            }
        }
        ToolbarItem {
            Button(action: onSave) {
                Image(systemName: "square.and.arrow.down")
            }
            .accessibilityLabel("Save as Preset")
            .help("Save as Preset")
        }
    }

    private func load(_ preset: SessionPreset) {
        if let config = SessionConfig.decoded(from: preset.configData) {
            onLoad(config)
        }
    }

    private func delete(_ preset: SessionPreset) {
        modelContext.delete(preset)
        modelContext.saveLogging()
    }
}
