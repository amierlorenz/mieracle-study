import MieracleKit

extension StudyMode {
    var title: String {
        switch self {
        case .review: "Review due"
        case .practice: "Practice"
        case .learnNew: "Learn new"
        }
    }

    var explanation: String {
        switch self {
        case .review: "Concepts whose review date has arrived."
        case .practice: "Anything in scope, due or not. Misses reschedule sooner; early successes don't push reviews later."
        case .learnNew: "Concepts you haven't studied, up to today's limit. You answer first, then see the explanation."
        }
    }
}

extension SessionConfig.Order {
    var title: String {
        switch self {
        case .interleaved: "Interleaved"
        case .blocked: "By unit"
        case .hardestFirst: "Hardest first"
        }
    }
}
