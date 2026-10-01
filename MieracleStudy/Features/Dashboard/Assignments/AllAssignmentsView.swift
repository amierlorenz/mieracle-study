import MieracleKit
import SwiftUI

struct AllAssignmentsView: View {
    let items: [CanvasItem]
    let courseNames: [Int: String]

    var body: some View {
        List(items) { item in
            AssignmentRow(item: item, courseName: courseNames[item.canvasCourseID])
        }
        .navigationTitle("Open Assignments")
    }
}
