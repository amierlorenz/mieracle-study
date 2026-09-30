import MieracleKit
import OSLog
import SwiftData
import SwiftUI

struct StudyView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.dailyNewLimit) private var dailyNewLimit = NewConceptBudget.defaultLimit
    @State private var engine: SessionEngine?
    @State private var message: String?

    var body: some View {
        NavigationStack {
            if let engine, engine.isFinished, engine.summary.answered > 0 {
                SessionSummaryView(engine: engine, onReviewAgain: reviewAgain, onDone: reset)
            } else if let engine, !engine.isFinished {
                SessionRunnerView(engine: engine)
            } else {
                SessionSetupView(message: message, onStart: start)
            }
        }
    }

    private func start(_ config: SessionConfig) {
        do {
            let engine = try SessionEngine(
                config: config,
                context: modelContext,
                dailyNewLimit: dailyNewLimit,
                supportsCodeExecution: Platform.supportsCodeExecution
            )
            message = engine.isFinished ? emptyMessage(for: config.mode) : nil
            self.engine = engine
        } catch {
            Logger.app.error("Starting session failed: \(error)")
            message = "Couldn't start the session."
        }
    }

    private func reviewAgain(_ conceptIDs: [String]) {
        start(SessionConfig(scope: .init(conceptIDs: Set(conceptIDs)), mode: .practice))
    }

    private func reset() {
        engine = nil
        message = nil
    }

    private func emptyMessage(for mode: StudyMode) -> String {
        switch mode {
        case .review: "Nothing is due in this scope. Try Practice or Learn New."
        case .practice: "No prompts match this scope and these prompt types."
        case .learnNew: "No new concepts left in this scope, or today's new-concept limit is reached."
        }
    }
}
