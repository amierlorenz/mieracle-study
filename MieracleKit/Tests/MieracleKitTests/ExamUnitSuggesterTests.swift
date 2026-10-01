import Foundation
import MieracleKit
import SwiftData
import Testing

@MainActor
struct ExamUnitSuggesterTests {
    let container: ModelContainer
    let context: ModelContext
    let course = Course(name: "CS")
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    init() throws {
        container = try ModelContainerFactory.make(storage: .inMemory)
        context = container.mainContext
        context.insert(course)
    }

    func week(_ n: Int) -> Date { start.addingTimeInterval(Double(n) * 7 * 86_400) }

    @discardableResult
    func unit(_ name: String, sort: Int, addedWeek: Int?) -> CourseUnit {
        let unit = CourseUnit(name: name, sortIndex: sort)
        unit.course = course
        if let addedWeek {
            let concept = Concept(title: "\(name) idea")
            concept.createdAt = week(addedWeek)
            concept.unit = unit
        }
        return unit
    }

    func exam(_ name: String, week n: Int, units: [CourseUnit] = []) -> Exam {
        let exam = Exam(name: name, date: week(n))
        context.insert(exam)
        exam.course = course
        exam.units = units
        return exam
    }

    @Test func finalCoversEverything() {
        unit("A", sort: 1, addedWeek: 1)
        unit("B", sort: 2, addedWeek: 5)
        #expect(ExamUnitSuggester.suggestUnits(for: exam("Final Exam", week: 15)).map(\.name) == ["A", "B"])
    }

    @Test func midtermCoversUnitsAddedSincePreviousExam() {
        let a = unit("A", sort: 1, addedWeek: 1)
        unit("B", sort: 2, addedWeek: 2)
        unit("C", sort: 3, addedWeek: 6)
        unit("D", sort: 4, addedWeek: 9)
        _ = exam("Midterm 1", week: 4, units: [a])
        #expect(ExamUnitSuggester.suggestUnits(for: exam("Midterm 2", week: 8)).map(\.name) == ["C"])
    }

    @Test func fallsBackToUncoveredUnits() {
        let a = unit("A", sort: 1, addedWeek: nil)
        unit("B", sort: 2, addedWeek: nil)
        _ = exam("Quiz 1", week: 2, units: [a])
        #expect(ExamUnitSuggester.suggestUnits(for: exam("Quiz 2", week: 4)).map(\.name) == ["B"])
    }
}
