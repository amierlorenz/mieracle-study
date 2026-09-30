import Foundation

/// Turns candidate concepts and a configuration into an ordered queue.
public struct SessionBuilder: Sendable {
    public var config: SessionConfig
    /// How many never-studied concepts may still be introduced today.
    public var newRemaining: Int
    /// Whether this device can run code (macOS only).
    public var supportsCodeExecution: Bool

    public init(config: SessionConfig, newRemaining: Int, supportsCodeExecution: Bool) {
        self.config = config
        self.newRemaining = newRemaining
        self.supportsCodeExecution = supportsCodeExecution
    }

    public func build(from candidates: [ConceptSnapshot], now: Date, using rng: inout some RandomNumberGenerator) -> [SessionItem] {
        var chosen = candidates.filter { config.scope.contains($0) && matchesMode($0, now: now) }
            .compactMap { concept in eligiblePrompt(for: concept, using: &rng).map { (concept, $0) } }

        if config.mode == .learnNew {
            chosen = Array(chosen.sorted { ($0.0.unitSortIndex, $0.0.createdAt, $0.0.id) < ($1.0.unitSortIndex, $1.0.createdAt, $1.0.id) }.prefix(newRemaining))
        }
        if case .count(let limit) = config.length, chosen.count > limit {
            chosen = Array(prioritized(chosen).prefix(limit))
        }

        let concepts = ordered(chosen.map(\.0), using: &rng)
        let prompts = Dictionary(uniqueKeysWithValues: chosen.map { ($0.0.id, $0.1) })
        return concepts.compactMap { concept in
            prompts[concept.id].map { SessionItem(conceptID: concept.id, promptID: $0.id, unitID: concept.unitID) }
        }
    }

    /// The prompts of a concept that this session may show.
    public func eligiblePrompts(of concept: ConceptSnapshot) -> [PromptSnapshot] {
        concept.prompts.filter { prompt in
            config.promptKinds.contains(prompt.kind)
                && !prompt.isFlagged
                && (supportsCodeExecution || !prompt.kind.requiresCodeRunner)
        }
    }

    private func matchesMode(_ concept: ConceptSnapshot, now: Date) -> Bool {
        switch config.mode {
        case .review: !concept.isNew && (concept.dueDate.map { $0 <= now } ?? false)
        case .learnNew: concept.isNew
        case .practice: true
        }
    }

    private func eligiblePrompt(for concept: ConceptSnapshot, using rng: inout some RandomNumberGenerator) -> PromptSnapshot? {
        let prompts = eligiblePrompts(of: concept).shuffled(using: &rng)
        return prompts.min { ($0.lastShownAt ?? .distantPast) < ($1.lastShownAt ?? .distantPast) }
    }

    private func prioritized(_ chosen: [(ConceptSnapshot, PromptSnapshot)]) -> [(ConceptSnapshot, PromptSnapshot)] {
        switch config.mode {
        case .review:
            chosen.sorted { ($0.0.dueDate ?? .distantFuture) < ($1.0.dueDate ?? .distantFuture) }
        case .practice:
            chosen.sorted { ($0.0.ease, -$0.0.lapses) < ($1.0.ease, -$1.0.lapses) }
        case .learnNew:
            chosen
        }
    }

    private func ordered(_ concepts: [ConceptSnapshot], using rng: inout some RandomNumberGenerator) -> [ConceptSnapshot] {
        switch config.order {
        case .interleaved:
            return interleaved(concepts, using: &rng)
        case .blocked:
            let groups = Dictionary(grouping: concepts, by: \.unitID)
            return groups.values
                .sorted { ($0[0].courseID, $0[0].unitSortIndex, $0[0].unitID) < ($1[0].courseID, $1[0].unitSortIndex, $1[0].unitID) }
                .flatMap { $0.shuffled(using: &rng) }
        case .hardestFirst:
            return concepts.shuffled(using: &rng).sorted { ($0.ease, -$0.lapses) < ($1.ease, -$1.lapses) }
        }
    }

    /// Repeatedly takes from the largest remaining unit that isn't the previous
    /// item's unit, so consecutive items share a unit only when nothing else is left.
    private func interleaved(_ concepts: [ConceptSnapshot], using rng: inout some RandomNumberGenerator) -> [ConceptSnapshot] {
        var groups = Dictionary(grouping: concepts, by: \.unitID).mapValues { $0.shuffled(using: &rng) }
        var result: [ConceptSnapshot] = []
        var previousUnit: String?
        while !groups.isEmpty {
            let candidates = groups.filter { $0.key != previousUnit }
            let pool = candidates.isEmpty ? groups : candidates
            let largest = pool.values.map(\.count).max() ?? 0
            let unit = pool.filter { $0.value.count == largest }.keys.sorted().randomElement(using: &rng)!
            result.append(groups[unit]!.removeLast())
            if groups[unit]!.isEmpty { groups[unit] = nil }
            previousUnit = unit
        }
        return result
    }
}
