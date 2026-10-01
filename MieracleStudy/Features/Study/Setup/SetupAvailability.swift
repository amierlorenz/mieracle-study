import Foundation
import MieracleKit

/// What the current selection offers: concepts per mode and prompts per kind.
struct SetupAvailability {
    let modeCounts: [StudyMode: Int]
    let kindCounts: [PromptKind: Int]

    init(concepts: [ConceptSnapshot], draft: SessionSetupDraft, newRemaining: Int, now: Date = .now) {
        guard !draft.scope.isEmpty else {
            modeCounts = [:]
            kindCounts = [:]
            return
        }
        let inScope = concepts.filter(draft.scope.contains)
        let allKinds = SessionBuilder(config: SessionConfig(scope: draft.scope), newRemaining: newRemaining, supportsCodeExecution: Platform.supportsCodeExecution)
        var kinds: [PromptKind: Int] = [:]
        for concept in inScope {
            for prompt in allKinds.eligiblePrompts(of: concept) {
                kinds[prompt.kind, default: 0] += 1
            }
        }
        kindCounts = kinds

        var modes: [StudyMode: Int] = [:]
        for mode in StudyMode.allCases {
            var config = draft.config
            config.mode = mode
            config.length = .all
            var rng = SystemRandomNumberGenerator()
            modes[mode] = SessionBuilder(config: config, newRemaining: newRemaining, supportsCodeExecution: Platform.supportsCodeExecution)
                .build(from: inScope, now: now, using: &rng)
                .count
        }
        modeCounts = modes
    }
}
