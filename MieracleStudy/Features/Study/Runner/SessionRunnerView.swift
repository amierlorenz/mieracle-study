import MieracleKit
import OSLog
import SwiftUI

struct SessionRunnerView: View {
    let engine: SessionEngine

    @AppStorage(SettingsKey.asksConfidence) private var showsConfidence = true
    @AppStorage(SettingsKey.blursChoices) private var blursChoices = true
    @AppStorage(SettingsKey.aiModel) private var aiModel = FoundationModelsProvider.ModelChoice.onDevice.rawValue

    var body: some View {
        VStack(spacing: 0) {
            SessionHeaderView(engine: engine)
            if let prompt = engine.currentPrompt, let concept = engine.currentConcept, case .fullProblem(let problem) = prompt.content {
                FullProblemCardView(prompt: prompt, problem: problem, concept: concept, mode: engine.config.mode, blursChoices: blursChoices, onGrade: answer)
                    .id(engine.position)
            } else if let prompt = engine.currentPrompt, let concept = engine.currentConcept {
                PromptCardView(prompt: prompt, concept: concept, mode: engine.config.mode, showsConfidence: showsConfidence, blursChoices: blursChoices, provider: FoundationModelsProvider(storedChoice: aiModel), onGrade: answer)
                    .id(engine.position)
            }
        }
        .navigationTitle(engine.config.mode.title)
        .toolbar {
            Button("End Session", systemImage: "stop.fill", action: finish)
        }
    }

    private func answer(_ grade: Grade, confidence: Confidence?, duration: TimeInterval) {
        do {
            try engine.answer(grade, confidence: confidence, duration: duration)
        } catch {
            Logger.app.error("Recording answer failed: \(error)")
        }
    }

    private func finish() {
        do {
            try engine.finish()
        } catch {
            Logger.app.error("Ending session failed: \(error)")
        }
    }
}
