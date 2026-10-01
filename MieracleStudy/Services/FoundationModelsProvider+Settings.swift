import MieracleKit

extension FoundationModelsProvider {
    /// The provider for the model chosen in Settings.
    init(storedChoice: String) {
        self.init(choice: ModelChoice(rawValue: storedChoice) ?? .onDevice)
    }
}

extension FoundationModelsProvider.ModelChoice {
    var title: String {
        switch self {
        case .onDevice: "On-device"
        case .privateCloud: "Private Cloud Compute"
        }
    }
}
