import MieracleKit
import SwiftUI

struct ExamReadinessRow: View {
    let exam: StudyOverview.ExamReadiness
    let onPrepare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(exam.name) · \(exam.courseName)")
                    .font(.headline)
                Spacer()
                Text(countdown)
                    .foregroundStyle(exam.daysLeft <= 3 ? .red : .secondary)
            }
            ProgressView(value: exam.studiedFraction) {
                Text("\(exam.studied) of \(exam.conceptCount) concepts studied · \(exam.weak) weak")
                    .font(.caption)
            }
            if exam.conceptCount == 0 {
                Text("No units mapped yet. Choose them in Exams.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Button("Exam Prep (25 min, weakest first)", systemImage: "target", action: onPrepare)
                    .buttonStyle(.glass)
            }
        }
    }

    private var countdown: String {
        switch exam.daysLeft {
        case 0: "Today"
        case 1: "Tomorrow"
        default: "In \(exam.daysLeft) days"
        }
    }
}
