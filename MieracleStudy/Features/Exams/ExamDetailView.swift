import MieracleKit
import SwiftData
import SwiftUI

struct ExamDetailView: View {
    @Bindable var exam: Exam

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ConceptTag.name) private var tags: [ConceptTag]

    init(exam: Exam) {
        self.exam = exam
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $exam.name)
                DatePicker("Date", selection: $exam.date)
                    .disabled(exam.canvasItemID != nil)
                LabeledContent("Class", value: exam.course?.name ?? "None")
            } footer: {
                if exam.canvasItemID != nil {
                    Text("The date comes from Canvas and updates on every sync.")
                }
            }
            Section {
                ForEach(exam.course?.sortedUnits ?? []) { unit in
                    Toggle(unit.name, isOn: membership(unit, in: \.units))
                }
            } header: {
                Text("Units covered")
            } footer: {
                Text("Concepts in these units are scheduled to come up before the exam.")
            }
            if !tags.isEmpty {
                Section("Tags covered") {
                    ForEach(tags) { tag in
                        Toggle(tag.name, isOn: membership(tag, in: \.tags))
                    }
                }
            }
            Section {
                Button("Delete Exam", role: .destructive, action: delete)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(exam.name)
        .onDisappear { modelContext.saveLogging() }
    }

    private func membership<Item: AnyObject>(_ item: Item, in keyPath: ReferenceWritableKeyPath<Exam, [Item]?>) -> Binding<Bool> {
        Binding {
            (exam[keyPath: keyPath] ?? []).contains { $0 === item }
        } set: { isOn in
            var items = exam[keyPath: keyPath] ?? []
            if isOn {
                items.append(item)
            } else {
                items.removeAll { $0 === item }
            }
            exam[keyPath: keyPath] = items
            modelContext.saveLogging()
        }
    }

    private func delete() {
        modelContext.delete(exam)
        modelContext.saveLogging()
        dismiss()
    }
}
