import MieracleKit
import SwiftUI

struct CanvasCoursePicker: View {
    @Bindable var course: Course
    let canvasCourses: [CanvasCourse]

    var body: some View {
        Picker(course.displayName, selection: $course.canvasCourseID) {
            Text("Not linked").tag(Int?.none)
            ForEach(canvasCourses) { canvasCourse in
                Text(canvasCourse.name).tag(Optional(canvasCourse.id))
            }
        }
    }
}
