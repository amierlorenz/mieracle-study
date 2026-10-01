import MieracleKit
import OSLog
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(VariantGenerationService.self) private var variantGeneration
    @AppStorage(SettingsKey.aiModel) private var aiModel = FoundationModelsProvider.ModelChoice.onDevice.rawValue
    @Environment(AppNavigation.self) private var navigation
    @Environment(CanvasService.self) private var canvas

    var body: some View {
        @Bindable var navigation = navigation
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $navigation.selection) { section in
                Label(section.title, systemImage: section.systemImage)
            }
            .navigationTitle("MieracleStudy")
        } detail: {
            SectionDetailView(section: navigation.selection ?? .dashboard)
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
        await canvas.syncIfDue(context: modelContext)
    }
}

#Preview {
    RootView()
        .environment(VariantGenerationService())
        .environment(AppNavigation())
        .environment(CanvasService())
        .modelContainer(try! ModelContainerFactory.make(storage: .inMemory))
}
