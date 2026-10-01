import MieracleKit
import SwiftUI

/// Optional "how sure are you?" choice. Picking one doesn't submit; tapping
/// the selected choice again clears it.
struct ConfidencePicker: View {
    @Binding var selection: Confidence?

    var body: some View {
        VStack(spacing: 6) {
            Text("How sure are you?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                ForEach(Confidence.allCases, id: \.self) { confidence in
                    ConfidenceChoice(confidence: confidence, isSelected: selection == confidence) {
                        selection = selection == confidence ? nil : confidence
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ConfidenceChoice: View {
    let confidence: Confidence
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        if isSelected {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }

    private var button: some View {
        Button(confidence.title, action: action)
            .controlSize(.small)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension Confidence {
    var title: String {
        switch self {
        case .sure: "Sure"
        case .unsure: "Not sure"
        case .noIdea: "No idea"
        }
    }
}
