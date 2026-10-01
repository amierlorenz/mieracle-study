import MieracleKit
import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKey.dailyNewLimit) private var dailyNewLimit = NewConceptBudget.defaultLimit
    @AppStorage(SettingsKey.asksConfidence) private var asksConfidence = false
    @AppStorage(SettingsKey.aiModel) private var aiModel = FoundationModelsProvider.ModelChoice.onDevice.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("New concepts per day: \(dailyNewLimit)", value: $dailyNewLimit, in: 0...200, step: 5)
                } header: {
                    Text("Learning")
                } footer: {
                    Text("Limits how many never-studied concepts Learn New introduces each day, so large imports don't flood future reviews.")
                }
                Section {
                    Toggle("Rate confidence before answers", isOn: $asksConfidence)
                } footer: {
                    Text("Before revealing an answer, tap how sure you are. Helps you notice when familiarity feels like knowing.")
                }
                AISettingsSection(aiModel: $aiModel)
                CanvasSettingsSection()
                #if os(macOS)
                CodingSettingsSection()
                #endif
                DataSettingsSection()
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .inlineTitleOnPhone()
        }
    }
}
