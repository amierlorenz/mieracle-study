import MieracleKit
import OSLog
import SwiftData
import SwiftUI

struct StudyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppNavigation.self) private var navigation
    @AppStorage(SettingsKey.dailyNewLimit) private var dailyNewLimit = NewConceptBudget.defaultLimit
    @Environment(\.undoManager) private var undoManager
    @State private var engine: SessionEngine?
    @State private var message: String?

    var body: some View {
        NavigationStack {
            if let engine, engine.isFinished, engine.summary.answered > 0 {
                SessionSummaryView(engine: engine, onReviewAgain: reviewAgain, onDone: finishToDashboard)
            } else if let engine, !engine.isFinished {
                SessionRunnerView(engine: engine)
            } else {
                SessionSetupView(message: message, onStart: start)
            }
        }
        .onChange(of: navigation.pendingSession, initial: true, startPending)
    }

    private func startPending() {
        guard let config = navigation.pendingSession else { return }
        navigation.pendingSession = nil
        start(config)
    }

    private func start(_ config: SessionConfig) {
        if let engine { undoManager?.removeAllActions(withTarget: engine) }
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

    private func finishToDashboard() {
        if let engine { undoManager?.removeAllActions(withTarget: engine) }
        engine = nil
        message = nil
        navigation.selection = .dashboard
    }

    private func emptyMessage(for mode: StudyMode) -> String {
        switch mode {
        case .review: "Nothing is due in this scope. Try Practice or Learn New."
        case .practice: "No prompts match this scope and these prompt types."
        case .learnNew: "No new concepts left in this scope, or today's new-concept limit is reached."
        }
    }
}
