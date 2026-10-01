import MieracleKit
import OSLog
import SwiftUI

/// Asks the AI provider for a grade suggestion and shows it.
struct AIGradeSection: View {
    let request: GradingRequest
    let provider: any AIProvider
    @Binding var suggestion: GradeSuggestion?

    @State private var failed = false

    var body: some View {
        Section("AI check") {
            if let suggestion {
                LabeledContent("Suggested grade", value: suggestion.grade.title)
                Text(suggestion.feedback)
                if !suggestion.missedKeyPoints.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Missing:")
                            .font(.subheadline.bold())
                        ForEach(suggestion.missedKeyPoints, id: \.self) { point in
                            Text("• \(point)")
                        }
                    }
                }
            } else if failed {
                Text("Couldn't check this answer. Grade it yourself.")
                    .foregroundStyle(.secondary)
            } else {
                ProgressView("Checking your answer…")
            }
        }
        .task(check)
    }

    private func check() async {
        guard suggestion == nil else { return }
        do {
            suggestion = try await provider.grade(request)
        } catch {
            Logger.app.error("AI grading failed: \(error)")
            failed = true
        }
    }
}
