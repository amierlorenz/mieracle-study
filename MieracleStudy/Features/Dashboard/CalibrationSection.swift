import MieracleKit
import SwiftData
import SwiftUI

/// Accuracy at each confidence level, shown once confidence ratings exist.
struct CalibrationSection: View {
    @Query private var reviews: [ReviewLog]

    var body: some View {
        let stats = CalibrationStats(logs: reviews)
        if !stats.levels.isEmpty {
            Section {
                ForEach(stats.levels) { level in
                    LabeledContent(level.confidence.title, value: "\(Int((level.accuracy * 100).rounded()))% right · \(level.answers) answers")
                }
            } header: {
                Text("Calibration")
            } footer: {
                Text(stats.insight ?? "From answers where you rated your confidence first.")
            }
        }
    }
}
