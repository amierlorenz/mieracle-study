import MieracleKit
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.name) private var courses: [Course]
    @State private var isAddingCourse = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(courses) { course in
                    NavigationLink(course.name, value: course)
                        .contextMenu {
                            Button("Delete", systemImage: "trash", role: .destructive) { delete(course) }
                        }
                }
                .onDelete(perform: deleteCourses)
            }
            .overlay {
                if courses.isEmpty {
                    ContentUnavailableView("No Classes", systemImage: "books.vertical", description: Text("Add a class or import a file."))
                }
            }
            .navigationTitle("Library")
            .toolbar {
                Button("Add Class", systemImage: "plus") { isAddingCourse = true }
            }
            .sheet(isPresented: $isAddingCourse) {
                NameEditorSheet(title: "New Class", onSave: addCourse)
            }
            .navigationDestination(for: Course.self, destination: CourseDetailView.init)
            .navigationDestination(for: CourseUnit.self, destination: UnitDetailView.init)
            .navigationDestination(for: Concept.self, destination: ConceptDetailView.init)
        }
    }

    private func addCourse(named name: String) {
        modelContext.insert(Course(name: name))
        modelContext.saveLogging()
    }

    private func delete(_ course: Course) {
        modelContext.delete(course)
        modelContext.saveLogging()
    }

    private func deleteCourses(at offsets: IndexSet) {
        offsets.map { courses[$0] }.forEach(modelContext.delete)
        modelContext.saveLogging()
    }
}
