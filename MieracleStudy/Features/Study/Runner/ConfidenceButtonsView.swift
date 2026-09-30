import MieracleKit
import SwiftUI

struct ConfidenceButtonsView: View {
    let onPick: (Confidence) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("How sure are you?")
                .font(.headline)
            HStack {
                ForEach(Confidence.allCases, id: \.self) { confidence in
                    Button(confidence.title) { onPick(confidence) }
                        .buttonStyle(.bordered)
                }
            }
        }
    }
}

extension Confidence {
    var title: String {
        switch self {
        case .sure: "Sure"
        case .unsure: "Unsure"
        case .noIdea: "No idea"
        }
    }
}
