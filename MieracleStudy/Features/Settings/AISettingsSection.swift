import MieracleKit
import SwiftUI

struct AISettingsSection: View {
    @Binding var aiModel: String

    @Environment(VariantGenerationService.self) private var variantGeneration

    var body: some View {
        Section {
            Picker("Model", selection: $aiModel) {
                ForEach(FoundationModelsProvider.ModelChoice.allCases, id: \.self) { choice in
                    Text(choice.title).tag(choice.rawValue)
                }
            }
            LabeledContent("Status", value: status)
            #if os(macOS)
            LabeledContent("Question variants", value: variantGeneration.isRunning ? "Generating…" : "Up to date")
            #endif
        } header: {
            Text("AI")
        } footer: {
            Text("AI suggests grades for written answers and rewords questions so you recall ideas instead of recognizing sentences. Private Cloud Compute uses Apple's larger server model and needs an entitlement from Apple; without it the on-device model is used.")
        }
    }

    private var status: String {
        let provider = FoundationModelsProvider(storedChoice: aiModel)
        guard provider.isAvailable else { return "Unavailable — grade answers yourself" }
        return "Using \(provider.activeModel.title)"
    }
}
