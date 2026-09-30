import MieracleKit
import SwiftData
import SwiftUI

struct UnitDetailView: View {
    let unit: CourseUnit

    @Environment(\.modelContext) private var modelContext
    @State private var isAddingConcept = false

    var body: some View {
        List {
            ForEach(sortedConcepts) { concept in
                NavigationLink(value: concept) {
                    LabeledContent(concept.title, value: "\(concept.prompts?.count ?? 0) prompts")
                }
                .contextMenu {
                    Button("Delete", systemImage: "trash", role: .destructive) { delete(concept) }
                }
            }
            .onDelete(perform: deleteConcepts)
        }
        .overlay {
            if sortedConcepts.isEmpty {
                ContentUnavailableView("No Concepts", systemImage: "lightbulb", description: Text("Add a concept or import a file."))
            }
        }
        .navigationTitle(unit.name)
        .toolbar {
            Button("Add Concept", systemImage: "plus") { isAddingConcept = true }
        }
        .sheet(isPresented: $isAddingConcept) {
            ConceptEditorSheet(title: "New Concept", draft: ConceptDraft(), onSave: addConcept)
        }
    }

    private var sortedConcepts: [Concept] {
        (unit.concepts ?? []).sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    private func addConcept(from draft: ConceptDraft) {
        let concept = Concept(title: draft.title)
        concept.unit = unit
        draft.apply(to: concept, in: modelContext)
        modelContext.saveLogging()
    }

    private func delete(_ concept: Concept) {
        modelContext.delete(concept)
        modelContext.saveLogging()
    }

    private func deleteConcepts(at offsets: IndexSet) {
        let concepts = sortedConcepts
        offsets.map { concepts[$0] }.forEach(modelContext.delete)
        modelContext.saveLogging()
    }
}
