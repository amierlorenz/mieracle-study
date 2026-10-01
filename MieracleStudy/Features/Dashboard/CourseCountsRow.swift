import MieracleKit
import SwiftUI

struct CourseCountsRow: View {
    let course: StudyOverview.CourseCounts
    let onReview: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(course.name)
                Text("\(course.due) due · \(course.new) new · \(course.total) concepts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Review", action: onReview)
                .buttonStyle(.glass)
                .disabled(course.due == 0)
        }
    }
}
