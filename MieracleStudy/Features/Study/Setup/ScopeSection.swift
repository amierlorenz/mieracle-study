import MieracleKit
import SwiftData
import SwiftUI

/// Checkbox tree of classes and units, plus tags.
struct ScopeSection: View {
    @Binding var scope: SessionConfig.Scope

    @Query(sort: \Course.name) private var courses: [Course]
    @Query(sort: \ConceptTag.name) private var tags: [ConceptTag]

    var body: some View {
        Section {
            ForEach(courses) { course in
                DisclosureGroup {
                    ForEach(course.sortedUnits) { unit in
                        Toggle(unit.name, isOn: membership(unit.externalID, in: \.unitIDs))
                            .disabled(scope.courseIDs.contains(course.externalID))
                    }
                } label: {
                    Toggle(course.name, isOn: membership(course.externalID, in: \.courseIDs))
                }
            }
            if !tags.isEmpty {
                DisclosureGroup("Tags") {
                    ForEach(tags) { tag in
                        Toggle(tag.name, isOn: membership(tag.name, in: \.tags))
                    }
                }
            }
        } header: {
            Text("What to study")
        } footer: {
            Text(scope.isEmpty ? "Nothing selected means everything." : "Selected classes include all of their units.")
        }
    }

    private func membership(_ id: String, in keyPath: WritableKeyPath<SessionConfig.Scope, Set<String>>) -> Binding<Bool> {
        Binding {
            scope[keyPath: keyPath].contains(id)
        } set: { isOn in
            if isOn {
                scope[keyPath: keyPath].insert(id)
            } else {
                scope[keyPath: keyPath].remove(id)
            }
        }
    }
}
