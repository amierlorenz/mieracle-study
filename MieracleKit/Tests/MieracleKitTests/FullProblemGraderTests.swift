import MieracleKit
import Testing

struct FullProblemGraderTests {
    @Test(arguments: [
        (true, true, 2, Grade.good),
        (nil, true, 2, .good),
        (false, true, 2, .hard),
        (true, true, 1, .hard),
        (true, false, 2, .again),
        (nil, false, 0, .again),
    ] as [(Bool?, Bool, Int, Grade)])
    func suggests(pattern: Bool?, tests: Bool, complexity: Int, expected: Grade) {
        #expect(FullProblemGrader.suggest(patternCorrect: pattern, testsPassed: tests, complexityCorrect: complexity) == expected)
    }
}
