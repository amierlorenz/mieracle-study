import Foundation
import MieracleKit
import Testing

struct ImportValidatorTests {
    func document(prompts: [ImportDocument.Prompt], exams: [ImportDocument.Exam] = []) -> ImportDocument {
        ImportDocument(courses: [
            .init(id: "c", name: "Course", units: [
                .init(id: "c.u", name: "Unit", concepts: [
                    .init(id: "c.u.k", title: "Concept", explanation: "", prompts: prompts),
                ]),
            ]),
        ], exams: exams)
    }

    func messages(_ document: ImportDocument, validator: ImportValidator = .init()) -> [String] {
        validator.validate(document).filter { $0.severity == .error }.map(\.description)
    }

    let card = ImportDocument.Prompt(id: "p1", content: .flashcard(.init(front: "Q", back: "A")))

    @Test func sampleFixtureIsValid() throws {
        let document = try ImportDocument.decode(from: ImportDocumentTests.fixture())
        #expect(ImportValidator().validate(document).isEmpty)
    }

    @Test func rejectsWrongSchemaVersion() {
        var doc = document(prompts: [card])
        doc.schemaVersion = 2
        #expect(messages(doc).contains { $0.contains("schemaVersion") })
    }

    @Test func rejectsDuplicateIDs() {
        let doc = document(prompts: [card, card])
        #expect(messages(doc) == ["error: courses[0].units[0].concepts[0].prompts[1]: Duplicate prompt id \"p1\" (first used at courses[0].units[0].concepts[0].prompts[0])."])
    }

    @Test(arguments: [
        (PromptContent.flashcard(.init(front: " ", back: "A")), "front is empty."),
        (.shortAnswer(.init(question: "Q", modelAnswer: "")), "modelAnswer is empty."),
        (.multipleChoice(.init(question: "Q", options: ["only"], correctIndex: 0)), "Needs at least two options."),
        (.multipleChoice(.init(question: "Q", options: ["a", "b"], correctIndex: 2)), "Index 2 is outside the 2 options."),
        (.codeImplement(.init(statement: "S", functionName: "two sum", starterCode: "", tests: [.init(args: [], expected: .null)])), "\"two sum\" isn't a valid function name."),
        (.codeImplement(.init(statement: "S", functionName: "f", starterCode: "", tests: [])), "Needs at least one test."),
        (.codeComplexity(.init(code: "x", time: "", space: "O(1)", explanation: "")), "time is empty."),
        (.patternPick(.init(statement: "S", options: ["a", "b"], answer: "a", explanation: "")), "options and correctIndex must be given together."),
        (.fullProblem(.init(statement: "S", pattern: "P", plan: "", functionName: "f", starterCode: "", tests: [.init(args: [], expected: .null)], time: "O(n)", space: "O(1)", explanation: "")), "plan is empty."),
        (.fullProblem(.init(statement: "S", pattern: "P", plan: "x", functionName: "f", starterCode: "", tests: [], time: "O(n)", space: "O(1)", explanation: "")), "Needs at least one test."),
        (.codeImplement(.init(statement: "S", language: .swift, functionName: "f", starterCode: "", tests: [.init(args: [], expected: .null)])), "Swift problems need a signature with parameter and return types."),
        (.codeImplement(.init(statement: "S", language: .swift, functionName: "f", starterCode: "", tests: [.init(args: [.number(1)], expected: .null)], signature: .init(parameters: [], returns: "Int"))), "Has 1 arguments but the signature has 0."),
    ])
    func rejectsInvalidPromptContent(content: PromptContent, expected: String) {
        let doc = document(prompts: [.init(id: "p", content: content)])
        #expect(messages(doc).contains { $0.hasSuffix(expected) })
    }

    @Test func checksExamReferences() {
        let exam = ImportDocument.Exam(id: "e", courseId: "other", name: "Final", date: "someday", unitIds: ["c.u", "missing"])
        let errors = messages(document(prompts: [card], exams: [exam]))
        #expect(errors.contains { $0.contains("Unknown course id \"other\"") })
        #expect(errors.contains { $0.contains("must be YYYY-MM-DD") })
        #expect(errors.contains { $0.contains("Unknown unit id \"missing\"") })
        #expect(!errors.contains { $0.contains("\"c.u\"") })
    }

    @Test func examsMayReferenceStoredIDs() {
        let exam = ImportDocument.Exam(id: "e", courseId: "stored", name: "Final", date: "2026-12-10", unitIds: ["stored.u"])
        let doc = ImportDocument(courses: [], exams: [exam])
        let validator = ImportValidator(knownCourseIDs: ["stored"], knownUnitIDs: ["stored.u"])
        #expect(messages(doc, validator: validator).isEmpty)
    }

    @Test func findsIDsDuplicatedAcrossFiles() {
        let first = document(prompts: [card])
        var second = document(prompts: [.init(id: "p2", content: card.content)])
        second.courses[0].units[0].concepts[0].id = "c.u.other"
        #expect(ImportValidator.crossDocumentDuplicates([("a.json", first), ("b.json", second)]).isEmpty)

        let issues = ImportValidator.crossDocumentDuplicates([("a.json", first), ("b.json", first)])
        #expect(issues.map(\.description) == [
            "error: b.json: Concept id \"c.u.k\" is also in a.json.",
            "error: b.json: Prompt id \"p1\" is also in a.json.",
        ])
    }

    @Test func warnsAboutConceptsWithoutPrompts() {
        let issues = ImportValidator().validate(document(prompts: []))
        #expect(issues.map(\.severity) == [.warning])
        #expect(!issues.hasErrors)
    }
}
