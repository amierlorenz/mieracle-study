import MieracleKit
import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.name) private var courses: [Course]
    @State private var isAddingCourse = false
    @State private var isSuggesting = false
    @AppStorage(SettingsKey.aiModel) private var aiModel = FoundationModelsProvider.ModelChoice.onDevice.rawValue

    var body: some View {
        NavigationStack {
            List {
                FlaggedPromptsSection()
                ForEach(courses) { course in
                    NavigationLink(course.displayName, value: course)
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
                Button(isSuggesting ? "Suggesting…" : "Suggest Short Names", systemImage: "wand.and.stars") {
                    Task { await suggestShortNames() }
                }
                .disabled(isSuggesting || courses.allSatisfy { $0.shortName != nil })
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

    /// Fills in short names for classes that don't have one.
    private func suggestShortNames() async {
        isSuggesting = true
        defer { isSuggesting = false }
        let suggester = ShortNameSuggester(provider: FoundationModelsProvider(storedChoice: aiModel))
        for course in courses where course.shortName == nil {
            course.shortName = await suggester.suggestion(for: course.name)
        }
        modelContext.saveLogging()
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
