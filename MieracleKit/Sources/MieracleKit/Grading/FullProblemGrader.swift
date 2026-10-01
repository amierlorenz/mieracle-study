/// Suggests a grade for a staged full problem.
///
/// Working code is the bar: failing tests suggest Again. Passing code with a
/// wrong pattern or complexity suggests Hard; everything right suggests Good.
public enum FullProblemGrader {
    /// - Parameters:
    ///   - patternCorrect: `nil` when the pattern was free text and can't be checked.
    ///   - testsPassed: whether the last run passed every test.
    ///   - complexityCorrect: how many of time and space matched (0–2).
    public static func suggest(patternCorrect: Bool?, testsPassed: Bool, complexityCorrect: Int) -> Grade {
        guard testsPassed else { return .again }
        return patternCorrect == false || complexityCorrect < 2 ? .hard : .good
    }
}
