import MieracleKit
import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.dailyNewLimit) private var dailyNewLimit = NewConceptBudget.defaultLimit
    @AppStorage(SettingsKey.asksConfidence) private var asksConfidence = true
    @AppStorage(SettingsKey.blursChoices) private var blursChoices = true
    @AppStorage(SettingsKey.aiModel) private var aiModel = FoundationModelsProvider.ModelChoice.onDevice.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        ImportView()
                    } label: {
                        Label("Import & Export", systemImage: "square.and.arrow.down.on.square")
                    }
                } footer: {
                    Text("Import study files, copy the AI generator prompt, or back up everything.")
                }
                Section {
                    Stepper("New concepts per day: \(dailyNewLimit)", value: $dailyNewLimit, in: 0...200, step: 5)
                } header: {
                    Text("Learning")
                } footer: {
                    Text("Limits how many never-studied concepts Learn New introduces each day, so large imports don't flood future reviews.")
                }
                Section {
                    Toggle("Show confidence buttons", isOn: $asksConfidence)
                    Toggle("Hide answer choices for 5 seconds", isOn: $blursChoices)
                } footer: {
                    Text("Confidence buttons (Sure, Not sure, No idea) are optional and feed the calibration stats. Hiding choices makes you recall the answer before recognizing it.")
                }
                AISettingsSection(aiModel: $aiModel)
                CanvasSettingsSection()
                #if os(macOS)
                CodingSettingsSection()
                #endif
                SyncSettingsSection()
                DataSettingsSection()
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .inlineTitleOnPhone()
        }
    }
}
