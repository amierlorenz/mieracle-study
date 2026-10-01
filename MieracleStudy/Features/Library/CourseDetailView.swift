import MieracleKit
import SwiftData
import SwiftUI

struct CourseDetailView: View {
    let course: Course

    @Environment(\.modelContext) private var modelContext
    @State private var isAddingUnit = false
    @State private var isRenaming = false
    @State private var editingUnit: CourseUnit?

    var body: some View {
        List {
            ShortNameSection(course: course)
            Section {
                Toggle("Programming class", isOn: codingBinding)
            } footer: {
                Text("Programming classes can use code prompt types (implement, complexity, pattern pick, full problem).")
            }
            ForEach(course.sortedUnits) { unit in
                NavigationLink(value: unit) {
                    LabeledContent(unit.name, value: "\(unit.concepts?.count ?? 0) concepts")
                }
                .contextMenu {
                    Button("Edit", systemImage: "pencil") { editingUnit = unit }
                    Button("Delete", systemImage: "trash", role: .destructive) { delete(unit) }
                }
            }
            .onDelete(perform: deleteUnits)
        }
        .overlay {
            if course.sortedUnits.isEmpty {
                ContentUnavailableView("No Units", systemImage: "folder", description: Text("Add a unit to start adding concepts."))
            }
        }
        .navigationTitle(course.displayName)
        .toolbar {
            Button("Rename Class", systemImage: "pencil") { isRenaming = true }
            Button("Add Unit", systemImage: "plus") { isAddingUnit = true }
        }
        .sheet(isPresented: $isAddingUnit) {
            UnitEditorSheet(title: "New Unit", sortIndex: course.sortedUnits.count + 1, onSave: addUnit)
        }
        .sheet(isPresented: $isRenaming) {
            NameEditorSheet(title: "Rename Class", name: course.name, onSave: rename)
        }
        .sheet(item: $editingUnit) { unit in
            UnitEditorSheet(title: "Edit Unit", name: unit.name, sortIndex: unit.sortIndex) { name, index in
                update(unit, name: name, sortIndex: index)
            }
        }
    }

    private var codingBinding: Binding<Bool> {
        Binding {
            course.allowsCodingPrompts
        } set: {
            course.allowsCodingPrompts = $0
            modelContext.saveLogging()
        }
    }

    private func addUnit(named name: String, sortIndex: Int) {
        let unit = CourseUnit(name: name, sortIndex: sortIndex)
        unit.course = course
        modelContext.saveLogging()
    }

    private func update(_ unit: CourseUnit, name: String, sortIndex: Int) {
        unit.name = name
        unit.sortIndex = sortIndex
        modelContext.saveLogging()
    }

    private func rename(to name: String) {
        course.name = name
        modelContext.saveLogging()
    }

    private func delete(_ unit: CourseUnit) {
        modelContext.delete(unit)
        modelContext.saveLogging()
    }

    private func deleteUnits(at offsets: IndexSet) {
        let units = course.sortedUnits
        offsets.map { units[$0] }.forEach(modelContext.delete)
        modelContext.saveLogging()
    }
}
