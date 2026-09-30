import MieracleKit

/// Form state for configuring a session.
struct SessionSetupDraft {
    enum LengthKind: String, CaseIterable, Identifiable {
        case all, count, minutes
        var id: Self { self }
    }

    var scope = SessionConfig.Scope()
    var mode = StudyMode.review
    var lengthKind = LengthKind.all
    var count = 20
    var minutes = 25
    var order = SessionConfig.Order.interleaved
    var promptKinds = Set(PromptKind.allCases)

    init() {}

    init(config: SessionConfig) {
        scope = config.scope
        mode = config.mode
        order = config.order
        promptKinds = config.promptKinds
        switch config.length {
        case .all: lengthKind = .all
        case .count(let n): lengthKind = .count; count = n
        case .minutes(let n): lengthKind = .minutes; minutes = n
        }
    }

    var config: SessionConfig {
        let length: SessionConfig.Length = switch lengthKind {
        case .all: .all
        case .count: .count(count)
        case .minutes: .minutes(minutes)
        }
        return SessionConfig(scope: scope, mode: mode, length: length, order: order, promptKinds: promptKinds)
    }
}
