import MieracleKit
import SwiftUI

/// A class to study: tap to select it all, or expand to pick units or concepts.
struct ClassCard: View {
    let course: Course
    let catalog: ScopeCatalog
    @Binding var scope: SessionConfig.Scope

    @State private var granularity = SelectionGranularity.unit

    var body: some View {
        let state = scope.state(ofCourse: course.externalID, in: catalog)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.displayName)
                        .font(.title3.bold())
                        .lineLimit(2)
                    if course.displayName != course.name {
                        Text(course.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                SelectionCircle(state: state)
                    .contentTransition(.symbolEffect(.replace))
            }
            statsText
                .font(.caption)
                .foregroundStyle(.secondary)
            if state == .some {
                Text("\(scope.selectedConceptCount(inCourse: course.externalID, in: catalog)) of \(conceptCount) concepts selected")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            ClassPartsPicker(course: course, catalog: catalog, granularity: granularity, scope: $scope)
                .transition(.opacity)
            HStack {
                Button(granularity == .unit ? "By Concept" : "By Unit", systemImage: granularity == .unit ? "list.bullet" : "square.grid.2x2") {
                    withAnimation(.spring(duration: 0.4)) {
                        granularity = granularity == .unit ? .concept : .unit
                    }
                }
                .contentTransition(.symbolEffect(.replace))
                SelectAllButtons(
                    canSelectAll: state != .all,
                    canDeselectAll: state != .none,
                    selectAll: { scope.setCourse(course.externalID, selected: true, in: catalog) },
                    deselectAll: { scope.setCourse(course.externalID, selected: false, in: catalog) }
                )
            }
            .buttonStyle(.glass)
            .controlSize(.small)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect(cornerRadius: 22))
        .onTapGesture {
            withAnimation(.spring(duration: 0.35)) { scope.toggleCourse(course.externalID, in: catalog) }
        }
        .glassEffect(state == .none ? .regular.interactive() : .regular.tint(.accentColor.opacity(0.16)).interactive(), in: .rect(cornerRadius: 22))
        .animation(.spring(duration: 0.35), value: state)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(state == .all ? .isSelected : [])
    }

    private var conceptCount: Int {
        course.sortedUnits.reduce(0) { $0 + ($1.concepts?.count ?? 0) }
    }

    private var statsText: Text {
        let concepts = course.sortedUnits.flatMap { $0.concepts ?? [] }
        let due = concepts.count { $0.isDue(at: .now) }
        let new = concepts.count(where: \.isNew)
        return Text("^[\(course.sortedUnits.count) unit](inflect: true) · ^[\(concepts.count) concept](inflect: true) · \(due) due · \(new) new")
    }
}
