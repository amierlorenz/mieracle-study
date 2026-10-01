import MieracleKit
import SwiftData
import SwiftUI

struct SessionSetupView: View {
    let message: String?
    let onStart: (SessionConfig) -> Void

    @State private var draft = SessionSetupDraft()
    @Query private var concepts: [Concept]

    var body: some View {
        Form {
            if let message {
                Section {
                    Label(message, systemImage: "info.circle")
                }
            }
            PresetsSection(current: draft.config) { draft = SessionSetupDraft(config: $0) }
            ScopeSection(scope: $draft.scope)
            Section {
                Picker("Mode", selection: $draft.mode) {
                    ForEach(StudyMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Mode")
            } footer: {
                Text(draft.mode.explanation)
            }
            Section("Length and order") {
                Picker("Length", selection: $draft.lengthKind) {
                    Text("All").tag(SessionSetupDraft.LengthKind.all)
                    Text("Number of items").tag(SessionSetupDraft.LengthKind.count)
                    Text("Time limit").tag(SessionSetupDraft.LengthKind.minutes)
                }
                switch draft.lengthKind {
                case .all:
                    EmptyView()
                case .count:
                    Stepper("\(draft.count) items", value: $draft.count, in: 5...200, step: 5)
                case .minutes:
                    Stepper("\(draft.minutes) minutes", value: $draft.minutes, in: 5...180, step: 5)
                }
                Picker("Order", selection: $draft.order) {
                    ForEach(SessionConfig.Order.allCases, id: \.self) { order in
                        Text(order.title).tag(order)
                    }
                }
            }
            PromptKindsSection(kinds: $draft.promptKinds, kindsInScope: kindsInScope)
            Section {
                Button("Start Session", systemImage: "play.fill") { onStart(draft.config) }
                    .buttonStyle(.borderedProminent)
                    .disabled(draft.promptKinds.isDisjoint(with: kindsInScope))
                    .keyboardShortcut(.defaultAction)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Study")
        .inlineTitleOnPhone()
    }

    private var kindsInScope: Set<PromptKind> {
        Set(concepts.map(ConceptSnapshot.init).filter(draft.scope.contains).flatMap { $0.prompts.filter { !$0.isFlagged }.map(\.kind) })
    }
}
