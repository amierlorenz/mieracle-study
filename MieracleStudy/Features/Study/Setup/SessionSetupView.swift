import MieracleKit
import SwiftData
import SwiftUI

struct SessionSetupView: View {
    let message: String?
    let onStart: (SessionConfig) -> Void

    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.dailyNewLimit) private var dailyNewLimit = NewConceptBudget.defaultLimit
    @Query(sort: \Course.name) private var courses: [Course]
    @Query(sort: \ConceptTag.name) private var tags: [ConceptTag]
    @Query private var concepts: [Concept]
    @State private var draft = SessionSetupDraft()
    @State private var isNamingPreset = false

    var body: some View {
        let catalog = ScopeCatalog(models: studyableCourses)
        let availability = availability
        ScrollView {
            VStack(spacing: 36) {
                if let message {
                    Label(message, systemImage: "info.circle")
                        .padding(12)
                        .glassEffect(in: .capsule)
                }
                if studyableCourses.isEmpty {
                    ContentUnavailableView("Nothing to Study Yet", systemImage: "books.vertical", description: Text("Import a file or add concepts to a class first."))
                } else {
                    ClassCardGrid(courses: studyableCourses, catalog: catalog, scope: $draft.scope)
                    if !tags.isEmpty {
                        TagChips(tags: tags, selection: $draft.scope.tags)
                    }
                    ModePicker(mode: $draft.mode, counts: availability.modeCounts)
                    PromptKindGrid(kinds: $draft.promptKinds, counts: availability.kindCounts)
                    LengthAndOrderPicker(draft: $draft)
                }
            }
            .padding(24)
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            if !studyableCourses.isEmpty {
                StartSessionBar(summary: summary(availability), isEnabled: canStart(availability)) {
                    onStart(draft.config)
                }
                .glassEffect(in: .rect(cornerRadius: 26))
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
        .navigationTitle("Study")
        .inlineTitleOnPhone()
        .toolbar {
            PresetsToolbar(current: draft.config, onLoad: { draft = SessionSetupDraft(config: $0) }, onSave: { isNamingPreset = true })
        }
        .sheet(isPresented: $isNamingPreset) {
            NameEditorSheet(title: "Save Preset", onSave: savePreset)
        }
        .onChange(of: availability.modeCounts) { _, counts in
            selectAvailableMode(counts)
        }
        #if DEBUG
        .onAppear {
            if DebugLaunchOptions.selectsAllOnSetup { draft.scope.selectAll(in: ScopeCatalog(models: studyableCourses)) }
        }
        #endif
    }

    /// Classes with at least one concept; empty classes can't be studied.
    private var studyableCourses: [Course] {
        courses.filter { course in course.sortedUnits.contains { !($0.concepts ?? []).isEmpty } }
    }

    private var availability: SetupAvailability {
        SetupAvailability(
            concepts: concepts.map(ConceptSnapshot.init),
            draft: draft,
            newRemaining: (try? NewConceptBudget.remaining(limit: dailyNewLimit, in: modelContext)) ?? dailyNewLimit
        )
    }

    private func canStart(_ availability: SetupAvailability) -> Bool {
        !draft.scope.isEmpty && (availability.modeCounts[draft.mode] ?? 0) > 0 && !draft.promptKinds.isDisjoint(with: availability.kindCounts.keys)
    }

    private func summary(_ availability: SetupAvailability) -> String {
        guard !draft.scope.isEmpty else { return "Choose at least one class." }
        let count = availability.modeCounts[draft.mode] ?? 0
        guard count > 0 else { return "Nothing to \(draft.mode.title.lowercased()) in this selection." }
        return "\(count) concepts · \(draft.mode.title) · \(draft.order.title)"
    }

    private func selectAvailableMode(_ counts: [StudyMode: Int]) {
        guard (counts[draft.mode] ?? 0) == 0, let available = StudyMode.allCases.first(where: { (counts[$0] ?? 0) > 0 }) else { return }
        withAnimation(.spring(duration: 0.35)) { draft.mode = available }
    }

    private func savePreset(named name: String) {
        modelContext.insert(SessionPreset(name: name, configData: draft.config.encoded()))
        modelContext.saveLogging()
    }
}
