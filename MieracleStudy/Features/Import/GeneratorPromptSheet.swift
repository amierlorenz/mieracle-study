import MieracleKit
import SwiftData
import SwiftUI

struct GeneratorPromptSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Course.name) private var courses: [Course]
    @State private var selectedCourseID: String?
    @State private var newCourseName = ""
    @State private var newCourseIsCoding = false
    @State private var didCopy = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Class") {
                    Picker("Class", selection: $selectedCourseID) {
                        Text("New class").tag(String?.none)
                        ForEach(courses) { course in
                            Text(course.name).tag(Optional(course.externalID))
                        }
                    }
                    if selectedCourse == nil {
                        TextField("New class name", text: $newCourseName)
                        Toggle("Programming class", isOn: $newCourseIsCoding)
                    } else if let selectedCourse {
                        LabeledContent("Prompt types", value: selectedCourse.allowsCodingPrompts ? "All, including code" : "Flashcard, short answer, multiple choice")
                    }
                }
                Section("Prompt") {
                    Text(generator.text)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("AI Generator Prompt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(didCopy ? "Copied" : "Copy Prompt", systemImage: "doc.on.doc", action: copy)
                        .disabled(selectedCourse == nil && newCourseName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .sheetFrame()
    }

    private var selectedCourse: Course? {
        courses.first { $0.externalID == selectedCourseID }
    }

    private var generator: GeneratorPrompt {
        guard let course = selectedCourse else {
            let name = newCourseName.trimmingCharacters(in: .whitespaces)
            return GeneratorPrompt(courseID: GeneratorPrompt.slug(name.isEmpty ? "course" : name), courseName: name.isEmpty ? "Course name" : name, isCodingClass: newCourseIsCoding)
        }
        let units = course.sortedUnits
        return GeneratorPrompt(
            courseID: course.externalID,
            courseName: course.name,
            units: units.map { .init(id: $0.externalID, name: $0.name) },
            existingConceptIDs: units.flatMap { ($0.concepts ?? []).map(\.externalID) },
            isCodingClass: course.allowsCodingPrompts
        )
    }

    private func copy() {
        Clipboard.copy(generator.text)
        didCopy = true
    }
}
