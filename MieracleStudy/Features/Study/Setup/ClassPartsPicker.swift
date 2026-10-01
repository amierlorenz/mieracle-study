import MieracleKit
import SwiftUI

/// Unit chips, or each unit's concept chips, inside an expanded class card.
struct ClassPartsPicker: View {
    let course: Course
    let catalog: ScopeCatalog
    let granularity: SelectionGranularity
    @Binding var scope: SessionConfig.Scope

    var body: some View {
        switch granularity {
        case .unit:
            FlowLayout {
                ForEach(units) { unit in
                    SelectableChip(title: unit.name, state: scope.state(ofUnit: unit.externalID, inCourse: course.externalID, in: catalog)) {
                        withAnimation(.spring(duration: 0.3)) {
                            scope.toggleUnit(unit.externalID, inCourse: course.externalID, in: catalog)
                        }
                    }
                }
            }
        case .concept:
            VStack(alignment: .leading, spacing: 12) {
                ForEach(units) { unit in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(unit.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        FlowLayout {
                            ForEach(concepts(of: unit)) { concept in
                                let isSelected = scope.isSelected(concept: concept.externalID, unitID: unit.externalID, courseID: course.externalID)
                                SelectableChip(title: concept.title, state: isSelected ? .all : .none) {
                                    withAnimation(.spring(duration: 0.3)) {
                                        scope.toggleConcept(concept.externalID, unitID: unit.externalID, courseID: course.externalID, in: catalog)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var units: [CourseUnit] {
        course.sortedUnits.filter { !($0.concepts ?? []).isEmpty }
    }

    private func concepts(of unit: CourseUnit) -> [Concept] {
        (unit.concepts ?? []).sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}

/// Whether expanded cards pick whole units or individual concepts.
enum SelectionGranularity: String, CaseIterable, Identifiable {
    case unit
    case concept

    var id: Self { self }

    var title: String {
        switch self {
        case .unit: "Units"
        case .concept: "Concepts"
        }
    }
}
