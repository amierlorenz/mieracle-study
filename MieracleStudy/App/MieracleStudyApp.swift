import MieracleKit
import OSLog
import SwiftData
import SwiftUI

@main
struct MieracleStudyApp: App {
    private let container: ModelContainer
    @State private var variantGeneration = VariantGenerationService()

    init() {
        container = Self.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(variantGeneration)
        }
        .modelContainer(container)
    }

    private static func makeContainer() -> ModelContainer {
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
