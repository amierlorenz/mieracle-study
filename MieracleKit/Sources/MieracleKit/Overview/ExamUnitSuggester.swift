import Foundation

/// Suggests which units an exam covers.
///
/// - A final covers every unit in the class.
/// - Otherwise: units whose concepts were added after the class's previous
///   exam and before this one, since material is usually imported as it's taught.
/// - If that finds nothing: units no earlier exam already covers.
@MainActor
public enum ExamUnitSuggester {
    public static func suggestUnits(for exam: Exam) -> [CourseUnit] {
        guard let course = exam.course else { return [] }
        let units = course.sortedUnits
        if exam.name.lowercased().contains(/\bfinal\b|\bcumulative\b/) {
            return units
        }
        let earlier = (course.exams ?? []).filter { $0 !== exam && $0.date < exam.date }
        let previousDate = earlier.map(\.date).max() ?? .distantPast

        let taughtBetween = units.filter { unit in
            guard let added = (unit.concepts ?? []).map(\.createdAt).min() else { return false }
            return added > previousDate && added <= exam.date
        }
        if !taughtBetween.isEmpty {
            return taughtBetween
        }
        let covered = Set(earlier.flatMap { ($0.units ?? []).map(\.persistentModelID) })
        return units.filter { !covered.contains($0.persistentModelID) }
    }
}
