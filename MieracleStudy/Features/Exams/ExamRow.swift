import MieracleKit
import SwiftUI

struct ExamRow: View {
    let exam: Exam

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(exam.name)
                if exam.canvasItemID != nil {
                    Image(systemName: "link")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Synced with Canvas")
                }
            }
            Text("\(exam.course?.name ?? "No class") · \(exam.date.formatted(date: .abbreviated, time: .shortened)) · \((exam.units ?? []).count) units")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
