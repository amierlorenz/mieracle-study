import MieracleKit
import OSLog
import SwiftData
import SwiftUI

@main
struct MieracleStudyApp: App {
    private let container: ModelContainer
    @State private var variantGeneration = VariantGenerationService()
    @State private var navigation = AppNavigation()
    @State private var canvas = CanvasService()
    @State private var syncStatus = SyncStatusService()

    init() {
        container = Self.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(variantGeneration)
                .environment(navigation)
                .environment(canvas)
                .environment(syncStatus)
                .task { syncStatus.start() }
        }
        .modelContainer(container)
    }

    private static func makeContainer() -> ModelContainer {
        #if DEBUG
        if DebugLaunchOptions.usesLocalStore, let container = try? ModelContainerFactory.make(storage: .local) {
            return container
        }
        #endif
        do {
            return try ModelContainerFactory.make(storage: .cloudSynced)
        } catch {
            Logger.app.error("CloudKit container failed, falling back to local store: \(error)")
        }
        do {
            return try ModelContainerFactory.make(storage: .local)
        } catch {
            fatalError("Unable to create model container: \(error)")
        }
    }
}
