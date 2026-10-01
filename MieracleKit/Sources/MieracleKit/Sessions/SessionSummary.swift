/// Results of a session, for the end-of-session screen.
public struct SessionSummary: Equatable, Sendable {
    /// Number of answers given, including repeats of failed items.
    public var answered: Int
    /// Each concept's worst grade in the session.
    public var worstGrades: [String: Grade]

    public init(answered: Int = 0, worstGrades: [String: Grade] = [:]) {
        self.answered = answered
        self.worstGrades = worstGrades
    }

    /// Concepts answered Again or Hard at least once, weakest first.
    public var needsWork: [String] {
        worstGrades.filter { !$0.value.isAtLeast(.good) }
            .sorted { ($0.value.rank, $0.key) < ($1.value.rank, $1.key) }
            .map(\.key)
    }

    public func count(of grade: Grade) -> Int {
        worstGrades.values.count { $0 == grade }
    }

    mutating func record(_ grade: Grade, for conceptID: String) {
        answered += 1
        if let current = worstGrades[conceptID], current.rank <= grade.rank { return }
        worstGrades[conceptID] = grade
    }
}

extension Grade {
    var rank: Int { Grade.allCases.firstIndex(of: self)! }

    public func isAtLeast(_ other: Grade) -> Bool { rank >= other.rank }
}
