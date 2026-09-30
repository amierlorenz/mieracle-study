import Foundation
import MieracleKit
import Testing

struct ImportDocumentTests {
    static func fixture(_ name: String = "sample-v1") throws -> Data {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }

    @Test func decodesSampleFixture() throws {
        let document = try ImportDocument.decode(from: Self.fixture())
        let course = try #require(document.courses.first)
        #expect(course.units.count == 2)
        #expect(course.units[0].concepts.flatMap(\.prompts).count == 6)
        #expect(course.units[1].concepts.isEmpty)
        #expect(document.exams.first?.unitIds == ["cs201.heaps"])
    }

    @Test func roundTripsThroughEncoding() throws {
        let document = try ImportDocument.decode(from: Self.fixture())
        #expect(try ImportDocument.decode(from: document.encoded()) == document)
    }

    @Test func reportsMissingFieldWithPath() {
        let json = #"{"schemaVersion": 1, "courses": [{"id": "c", "units": []}]}"#
        #expect {
            try ImportDocument.decode(from: Data(json.utf8))
        } throws: { error in
            (error as? ImportDecodingError)?.message.hasPrefix("courses[0].name") == true
        }
    }

    @Test(arguments: [
        ("2026-11-04", true),
        ("2026-11-04T14:30:00Z", true),
        ("Nov 4", false),
    ])
    func parsesExamDates(text: String, isValid: Bool) {
        let exam = ImportDocument.Exam(id: "e", courseId: "c", name: "Exam", date: text)
        #expect((exam.parsedDate() != nil) == isValid)
    }

    @Test func dayOnlyDateIsLocalStartOfDay() throws {
        let timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let exam = ImportDocument.Exam(id: "e", courseId: "c", name: "Exam", date: "2026-11-04")
        let date = try #require(exam.parsedDate(in: timeZone))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        #expect(calendar.dateComponents([.year, .month, .day, .hour], from: date) == DateComponents(year: 2026, month: 11, day: 4, hour: 0))
    }
}
