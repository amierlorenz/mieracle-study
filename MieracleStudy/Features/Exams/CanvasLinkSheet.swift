import MieracleKit
import SwiftData
import SwiftUI

/// Matches each class to its Canvas course so assignments and exam dates sync.
struct CanvasLinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(CanvasService.self) private var canvas
    @Query(sort: \Course.name) private var courses: [Course]
    @State private var canvasCourses: [CanvasCourse] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                ForEach(courses) { course in
                    CanvasCoursePicker(course: course, canvasCourses: canvasCourses)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Link Classes")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: done)
                }
            }
            .task(loadCourses)
        }
        .sheetFrame()
    }

    private func loadCourses() async {
        guard let client = canvas.client() else { return }
        do {
            canvasCourses = try await client.activeCourses()
        } catch {
            errorMessage = "Couldn't load Canvas courses: \(error.localizedDescription)"
        }
    }

    private func done() {
        modelContext.saveLogging()
        dismiss()
        Task { await canvas.sync(context: modelContext) }
    }
}
