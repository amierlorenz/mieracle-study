import MieracleKit
import Observation
import OSLog
import SwiftData

/// Runs AI content generation in the background on the Mac, one run at a time:
/// prompts for lean-imported concepts first, then question variants.
@MainActor
@Observable
final class VariantGenerationService {
    private(set) var isRunning = false
    private(set) var lastCreated = 0
    @ObservationIgnored private var needsRerun = false

    func start(context: ModelContext, provider: any AIProvider) {
        #if os(macOS)
        guard !isRunning else {
            needsRerun = true
            return
        }
        isRunning = true
        Task {
            repeat {
                needsRerun = false
                do {
                    try await PromptGenerator(context: context, provider: provider).run()
                    lastCreated = try await VariantGenerator(context: context, provider: provider).run()
                } catch {
                    Logger.app.error("Variant generation stopped: \(error)")
                }
            } while needsRerun
            isRunning = false
        }
        #endif
    }
}
