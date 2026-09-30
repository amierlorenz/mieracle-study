import Foundation
import MieracleKit
import Testing

struct PromptContentTests {
    static let samples: [PromptContent] = [
        .flashcard(.init(front: "Big-O of binary search?", back: "$O(\\log n)$")),
        .shortAnswer(.init(question: "Why use a heap?", modelAnswer: "Fast min access", keyPoints: ["O(1) peek", "O(log n) push"])),
        .multipleChoice(.init(question: "Stable sort?", options: ["Quick", "Merge"], correctIndex: 1, explanation: "Merge sort is stable.")),
        .codeImplement(.init(
            statement: "Return the sum.",
            functionName: "add",
            starterCode: "def add(a, b):\n    pass",
            tests: [.init(args: [.number(1), .number(2)], expected: .number(3)), .init(args: [.number(0), .number(0)], expected: .number(0), isHidden: true)],
            comparison: .exact
        )),
        .codeComplexity(.init(code: "for i in range(n): pass", time: "O(n)", space: "O(1)", explanation: "One loop.")),
        .patternPick(.init(statement: "Top k elements?", options: ["Heap", "Stack"], correctIndex: 0, answer: "Heap", explanation: "Size-k heap.")),
    ]

    @Test(arguments: samples)
    func roundTrips(content: PromptContent) throws {
        let data = try JSONEncoder().encode(content)
        #expect(try JSONDecoder().decode(PromptContent.self, from: data) == content)
    }

    @Test(arguments: samples)
    func encodesTypeDiscriminator(content: PromptContent) throws {
        let data = try JSONEncoder().encode(content)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["type"] as? String == content.kind.rawValue)
    }

    @Test func decodesFlatImportShapeWithDefaults() throws {
        let json = """
        {"type": "codeImplement", "statement": "Reverse", "functionName": "rev",
         "tests": [{"args": [[1, 2]], "expected": [2, 1]}]}
        """
        let content = try JSONDecoder().decode(PromptContent.self, from: Data(json.utf8))
        guard case .codeImplement(let problem) = content else {
            Issue.record("Expected codeImplement")
            return
        }
        #expect(problem.language == .python)
        #expect(problem.comparison == .exact)
        #expect(problem.starterCode.isEmpty)
        #expect(problem.tests.first?.isHidden == false)
        #expect(problem.tests.first?.expected == .array([.number(2), .number(1)]))
    }

    @Test func rejectsUnknownType() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PromptContent.self, from: Data(#"{"type": "essay"}"#.utf8))
        }
    }

    @Test func jsonValueKeepsIntegersAsIntegers() throws {
        let value = JSONValue.array([.number(3), .number(2.5), .bool(true), .null, .string("x")])
        let text = String(decoding: try JSONEncoder().encode(value), as: UTF8.self)
        #expect(text == #"[3,2.5,true,null,"x"]"#)
    }
}
