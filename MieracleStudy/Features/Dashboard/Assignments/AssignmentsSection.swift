import MieracleKit
import SwiftData
import SwiftUI

/// Canvas work surfacing today, with a link to every open assignment.
struct AssignmentsSection: View {
    @Query(sort: \CanvasItem.dueAt) private var items: [CanvasItem]
    @Query private var courses: [Course]

    var body: some View {
        let schedule = AssignmentSchedule()
        let today = schedule.today(items, now: .now)
        let open = schedule.open(items, now: .now)
        if !open.isEmpty {
            Section {
                ForEach(today) { item in
                    AssignmentRow(item: item, courseName: courseName(for: item))
                }
                if today.isEmpty {
                    Text("Nothing due in the next two weeks.")
                        .foregroundStyle(.secondary)
                }
                NavigationLink("All open assignments (\(open.count))") {
                    AllAssignmentsView(items: open, courseNames: courseNames)
                }
            } header: {
                Text("Assignments")
            } footer: {
                Text("From Canvas. Work shows up two weeks before it's due, or when it opens.")
            }
        }
    }

    private var courseNames: [Int: String] {
        Dictionary(courses.compactMap { course in course.canvasCourseID.map { ($0, course.name) } }, uniquingKeysWith: { first, _ in first })
    }

    private func courseName(for item: CanvasItem) -> String? {
        courseNames[item.canvasCourseID]
    }
}
