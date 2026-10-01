import Foundation
import MieracleKit
import Testing

struct CalibrationStatsTests {
    func logs(_ entries: [(Confidence?, Grade)]) -> [ReviewLog] {
        entries.map { ReviewLog(grade: $0.1, confidence: $0.0, duration: 1, mode: .review, wasDue: true, wasNew: false) }
    }

    @Test func groupsAccuracyByConfidence() {
        let stats = CalibrationStats(logs: logs([(.sure, .good), (.sure, .again), (.unsure, .hard), (.noIdea, .easy), (nil, .good)]))
        #expect(stats.levels.map(\.confidence) == [.sure, .unsure, .noIdea])
        #expect(stats.levels[0].accuracy == 0.5)
        #expect(stats.levels[1].correct == 0)
        #expect(stats.insight == nil)
    }

    @Test(arguments: [(6, "familiarity may be feeling like knowing"), (9, "well calibrated")])
    func insightNeedsTenSureAnswers(correct: Int, phrase: String) {
        let entries: [(Confidence?, Grade)] = (0..<10).map { (.sure, $0 < correct ? .good : .again) }
        #expect(CalibrationStats(logs: logs(entries)).insight?.contains(phrase) == true)
    }
}
