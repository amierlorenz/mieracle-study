import MieracleKit
import SwiftUI

struct ClassCardGrid: View {
    let courses: [Course]
    let catalog: ScopeCatalog
    @Binding var scope: SessionConfig.Scope

    var body: some View {
        VStack(spacing: 14) {
            SectionTitle(title: "What do you want to study?", subtitle: "Tap a class to select all of it, or pick its units or concepts.")
            HStack {
                SelectAllButtons(
                    canSelectAll: courses.contains { scope.state(ofCourse: $0.externalID, in: catalog) != .all },
                    canDeselectAll: !scope.isEmpty,
                    selectAll: { scope.selectAll(in: catalog) },
                    deselectAll: { scope.deselectAll() }
                )
            }
            .buttonStyle(.glass)
            .controlSize(.small)
            .animation(.spring(duration: 0.35), value: scope)
            MasonryLayout {
                ForEach(courses) { course in
                    ClassCard(course: course, catalog: catalog, scope: $scope)
                }
            }
        }
    }
}
