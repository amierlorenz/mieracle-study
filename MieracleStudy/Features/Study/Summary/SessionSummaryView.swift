import MieracleKit
import SwiftUI

struct SessionSummaryView: View {
    let engine: SessionEngine
    let onReviewAgain: ([String]) -> Void
    let onDone: () -> Void

    var body: some View {
        Form {
            Section("Session complete") {
                LabeledContent("Answers", value: "\(engine.summary.answered)")
                ForEach(Grade.allCases, id: \.self) { grade in
                    LabeledContent(grade.title, value: "\(engine.summary.count(of: grade)) concepts")
                }
            }
            if !needsWork.isEmpty {
                Section {
                    ForEach(needsWork) { concept in
                        DisclosureGroup(concept.title) {
                            ConceptExplanationView(concept: concept)
                        }
                    }
                } header: {
                    Text("Worth another look")
                } footer: {
                    Text("Missed or hard this session. They're already scheduled to come back soon.")
                }
            }
            ReflectionSection(engine: engine)
            Section {
                HStack {
                    if !needsWork.isEmpty {
                        Button("Review These Again", systemImage: "arrow.counterclockwise") {
                            onReviewAgain(engine.summary.needsWork)
                        }
                    }
                    Spacer()
                    Button("Done", action: onDone)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Summary")
        .inlineTitleOnPhone()
    }

    private var needsWork: [Concept] {
        engine.summary.needsWork.compactMap(engine.concept(withID:))
    }
}
