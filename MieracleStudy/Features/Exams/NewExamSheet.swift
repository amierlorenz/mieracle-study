import MieracleKit
import SwiftData
import SwiftUI

struct NewExamSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.name) private var courses: [Course]
    @State private var name = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now
    @State private var courseID: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name, prompt: Text("Midterm 2"))
                DatePicker("Date", selection: $date)
                Picker("Class", selection: $courseID) {
                    Text("Choose…").tag(String?.none)
                    ForEach(courses) { course in
                        Text(course.name).tag(Optional(course.externalID))
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Exam")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: add)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || courseID == nil)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 240)
        #endif
    }

    private func add() {
        let exam = Exam(name: name.trimmingCharacters(in: .whitespaces), date: date)
        modelContext.insert(exam)
        exam.course = courses.first { $0.externalID == courseID }
        modelContext.saveLogging()
        dismiss()
    }
}
