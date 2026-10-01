import SwiftUI

struct TodaySection: View {
    let due: Int
    let newRemaining: Int
    let reviewedToday: Int
    let onReview: () -> Void
    let onLearn: () -> Void

    var body: some View {
        Section("Today") {
            LabeledContent("Due for review", value: "\(due)")
            LabeledContent("New concepts left today", value: "\(newRemaining)")
            LabeledContent("Answered today", value: "\(reviewedToday)")
            HStack {
                Button("Review Due", systemImage: "arrow.counterclockwise", action: onReview)
                    .buttonStyle(.borderedProminent)
                    .disabled(due == 0)
                Button("Learn New", systemImage: "sparkles", action: onLearn)
                    .disabled(newRemaining == 0)
            }
        }
    }
}
