/// How often answers were right at each confidence level, which shows whether
/// feeling sure matches knowing (*Make It Stick*: calibration).
public struct CalibrationStats: Equatable, Sendable {
    public struct Level: Equatable, Sendable, Identifiable {
        public var confidence: Confidence
        public var answers: Int
        /// Answers graded Good or Easy.
        public var correct: Int

        public var id: Confidence { confidence }
        public var accuracy: Double { answers == 0 ? 0 : Double(correct) / Double(answers) }
    }

    public var levels: [Level]

    public init(logs: [ReviewLog]) {
        levels = Confidence.allCases.compactMap { confidence in
            let rated = logs.filter { $0.confidence == confidence }
            guard !rated.isEmpty else { return nil }
            return Level(confidence: confidence, answers: rated.count, correct: rated.count { $0.grade.isAtLeast(.good) })
        }
    }

    /// A one-line reading of the numbers, or `nil` without enough data.
    public var insight: String? {
        guard let sure = levels.first(where: { $0.confidence == .sure }), sure.answers >= 10 else { return nil }
        let percent = Int((sure.accuracy * 100).rounded())
        if sure.accuracy < 0.7 {
            return "When sure, you were right \(percent)% of the time: familiarity may be feeling like knowing."
        }
        return "When sure, you were right \(percent)% of the time: your confidence is well calibrated."
    }
}
