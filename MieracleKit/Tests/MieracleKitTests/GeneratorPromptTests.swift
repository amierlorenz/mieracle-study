import Foundation
import MieracleKit
import Testing

struct GeneratorPromptTests {
    let prompt = GeneratorPrompt(
        courseID: "cs201",
        courseName: "CS 201",
        units: [.init(id: "cs201.heaps", name: "Heaps")],
        existingConceptIDs: ["cs201.heaps.top-k"]
    )

    @Test func includesCourseUnitsAndExistingIDs() {
        #expect(prompt.text.contains("Course id: `cs201`"))
        #expect(prompt.text.contains("`cs201.heaps` — Heaps"))
        #expect(prompt.text.contains("`cs201.heaps.top-k`"))
    }

    @Test func documentsEveryPromptKind() {
        for kind in PromptKind.allCases {
            #expect(prompt.text.contains("\"type\": \"\(kind.rawValue)\""))
        }
    }

    @Test func exampleBlockIsValidJSON() throws {
        let text = prompt.text
        let start = try #require(text.range(of: "```json\n{"))
        let end = try #require(text.range(of: "\n```", range: start.upperBound..<text.endIndex))
        let json = String(text[text.index(start.upperBound, offsetBy: -1)..<end.lowerBound])
        #expect(throws: Never.self) {
            try JSONSerialization.jsonObject(with: Data(json.utf8))
        }
    }

    @Test(arguments: [("Heaps & Priority Queues", "heaps-priority-queues"), ("  Big-O  ", "big-o"), ("Unit 3: Graphs", "unit-3-graphs")])
    func slugs(input: String, expected: String) {
        #expect(GeneratorPrompt.slug(input) == expected)
    }
}

extension GeneratorPromptTests {
    @Test func nonCodingClassesListOnlyNonCodingKinds() {
        let general = GeneratorPrompt(courseID: "mis", courseName: "Make It Stick")
        #expect(general.allowedKinds == [.flashcard, .shortAnswer, .multipleChoice])
        #expect(general.text.contains("never use code prompt types"))

        let coding = GeneratorPrompt(courseID: "cs", courseName: "CS", isCodingClass: true)
        #expect(coding.allowedKinds == PromptKind.allCases)
        #expect(coding.text.contains("\"coding\": true"))
    }
}
