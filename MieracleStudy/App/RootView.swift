import MieracleKit
import OSLog
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(VariantGenerationService.self) private var variantGeneration
    @AppStorage(SettingsKey.aiModel) private var aiModel = FoundationModelsProvider.ModelChoice.onDevice.rawValue
    @State private var selection: SidebarSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
            }
            .navigationTitle("MieracleStudy")
        } detail: {
            SectionDetailView(section: selection ?? .dashboard)
        }
        .task(prepareStore)
    }

    private func prepareStore() async {
        do {
            try DuplicateMerger.mergeAll(in: modelContext)
        } catch {
            Logger.app.error("Duplicate merge failed: \(error)")
        }
        variantGeneration.start(context: modelContext, provider: FoundationModelsProvider(storedChoice: aiModel))
    }
}

#Preview {
    RootView()
        .environment(VariantGenerationService())
        .modelContainer(try! ModelContainerFactory.make(storage: .inMemory))
}
