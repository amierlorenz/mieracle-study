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
    @State private var selectedToAdd: Set<Int> = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                if !unlinkedCourses.isEmpty {
                    Section {
                        ForEach(unlinkedCourses) { canvasCourse in
                            Toggle(canvasCourse.name, isOn: selection(for: canvasCourse.id))
                        }
                        Button("Add \(selectedToAdd.count) as Classes", systemImage: "plus.circle", action: addSelected)
                            .disabled(selectedToAdd.isEmpty)
                    } header: {
                        Text("Add classes from Canvas")
                    } footer: {
                        Text("Rename classes anytime in the Library; they stay linked to Canvas.")
                    }
                }
                if !courses.isEmpty {
                    Section("Link existing classes") {
                        ForEach(courses) { course in
                            CanvasCoursePicker(course: course, canvasCourses: canvasCourses)
                        }
                    }
                }
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
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

    private var unlinkedCourses: [CanvasCourse] {
        let linked = Set(courses.compactMap(\.canvasCourseID))
        return canvasCourses.filter { !linked.contains($0.id) }
    }

    private func selection(for id: Int) -> Binding<Bool> {
        Binding {
            selectedToAdd.contains(id)
        } set: { isOn in
            if isOn { selectedToAdd.insert(id) } else { selectedToAdd.remove(id) }
        }
    }

    private func addSelected() {
        do {
            try CanvasSync.importCourses(canvasCourses.filter { selectedToAdd.contains($0.id) }, into: modelContext)
            selectedToAdd = []
        } catch {
            errorMessage = "Couldn't add classes: \(error.localizedDescription)"
        }
    }

    private func done() {
        modelContext.saveLogging()
        dismiss()
        Task { await canvas.sync(context: modelContext) }
    }
}
