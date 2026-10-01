import MieracleKit
import SwiftData
import SwiftUI

/// Edit a class's short name, or ask for a suggestion.
struct ShortNameSection: View {
    @Bindable var course: Course

    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.aiModel) private var aiModel = FoundationModelsProvider.ModelChoice.onDevice.rawValue
    @State private var isSuggesting = false

    var body: some View {
        Section {
            HStack {
                TextField("Short name", text: shortName, prompt: Text(verbatim: "CSC 395 | Swift"))
                Button(isSuggesting ? "Suggesting…" : "Suggest", systemImage: "wand.and.stars") {
                    Task { await suggest() }
                }
                .buttonStyle(.glass)
                .disabled(isSuggesting)
            }
        } header: {
            Text("Short name")
        } footer: {
            Text("Shown on cards and lists. Full name: \(course.name)")
        }
    }

    private var shortName: Binding<String> {
        Binding {
            course.shortName ?? ""
        } set: {
            course.shortName = $0.isEmpty ? nil : $0
            modelContext.saveLogging()
        }
    }

    private func suggest() async {
        isSuggesting = true
        defer { isSuggesting = false }
        course.shortName = await ShortNameSuggester(provider: FoundationModelsProvider(storedChoice: aiModel)).suggestion(for: course.name)
        modelContext.saveLogging()
    }
}
