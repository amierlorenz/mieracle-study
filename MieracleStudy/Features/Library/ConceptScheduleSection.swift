import MieracleKit
import SwiftUI

struct ConceptScheduleSection: View {
    let concept: Concept

    var body: some View {
        Section("Schedule") {
            if concept.isNew {
                Text("New — not studied yet")
            } else {
                LabeledContent("Due", value: concept.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "—")
                LabeledContent("Interval", value: "\(concept.intervalDays.formatted()) days")
                LabeledContent("Ease", value: concept.ease.formatted(.number.precision(.fractionLength(2))))
                LabeledContent("Reviews", value: "\(concept.repetitions) in a row, \(concept.lapses) lapses")
            }
        }
    }
}
