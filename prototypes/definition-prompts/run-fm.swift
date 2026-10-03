// PROTOTYPE — throwaway. Usage: swift run-fm.swift  (reads out/records.json → out/fm.json)
import Foundation
import FoundationModels

@Generable
struct Generated {
    var flashcard: Flashcard
    var shortAnswer: ShortAnswer
    var multipleChoice: MultipleChoice
}

@Generable
struct Flashcard {
    @Guide(description: "Question asking for one key idea")
    var front: String
    @Guide(description: "Answer, one or two sentences")
    var back: String
}

@Generable
struct ShortAnswer {
    @Guide(description: "Asks the student to state, explain, or apply the concept")
    var question: String
    @Guide(description: "Model answer, two or three sentences")
    var modelAnswer: String
    @Guide(description: "Points a correct answer must mention", .count(2...4))
    var keyPoints: [String]
}

@Generable
struct MultipleChoice {
    var question: String
    @Guide(description: "Exactly 4 options of similar length, one correct", .count(4))
    var options: [String]
    @Guide(description: "0-based index of the correct option", .range(0...3))
    var correctIndex: Int
    @Guide(description: "Why the correct option is right and what the most tempting wrong one gets wrong")
    var explanation: String
}

struct Record: Decodable {
    let id, title, kind, record: String
}

let here = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let records = try JSONDecoder().decode([Record].self, from: Data(contentsOf: here.appending(path: "out/records.json")))
let instructions = try String(contentsOf: here.appending(path: "prompt.md"), encoding: .utf8)

guard SystemLanguageModel.default.isAvailable else {
    print("fm: on-device model unavailable: \(SystemLanguageModel.default.availability)")
    exit(1)
}

var results: [[String: Any]] = []
let start = Date()
for record in records {
    let t0 = Date()
    let session = LanguageModelSession(model: .default, instructions: instructions)
    var entry: [String: Any] = ["id": record.id, "title": record.title]
    do {
        let g = try await session.respond(to: record.record, generating: Generated.self).content
        entry["prompts"] = [
            "flashcard": ["front": g.flashcard.front, "back": g.flashcard.back],
            "shortAnswer": ["question": g.shortAnswer.question, "modelAnswer": g.shortAnswer.modelAnswer, "keyPoints": g.shortAnswer.keyPoints],
            "multipleChoice": ["question": g.multipleChoice.question, "options": g.multipleChoice.options,
                               "correctIndex": g.multipleChoice.correctIndex, "explanation": g.multipleChoice.explanation],
        ]
    } catch {
        entry["error"] = "\(error)"
    }
    entry["seconds"] = (Date().timeIntervalSince(t0) * 10).rounded() / 10
    results.append(entry)
    print("fm: \(record.title): \(entry["seconds"]!)s\(entry["error"].map { " ERROR \($0)" } ?? "")")
}
let meta: [String: Any] = ["provider": "Foundation Models on-device", "seconds": Int(Date().timeIntervalSince(start)), "requests": 0]
let data = try JSONSerialization.data(withJSONObject: ["meta": meta, "results": results], options: [.prettyPrinted, .sortedKeys])
try data.write(to: here.appending(path: "out/fm.json"))
print("fm: \(results.count) concepts in \(meta["seconds"]!)s")
