// PROTOTYPE — throwaway. Usage: swift run-fm.swift <deck.pdf>
import Foundation
import FoundationModels
import PDFKit

@Generable
struct PageConcepts {
    @Guide(description: "Concepts taught on this page", .maximumCount(8))
    var concepts: [Candidate]
}

@Generable
struct Candidate {
    @Guide(description: "Short name of the concept, as the course names it")
    var title: String
    var kind: Kind
    @Guide(description: "Correct, self-contained definition or statement; LaTeX in $...$ for math")
    var definition: String
    @Guide(description: "Short quote copied character-for-character from the page text; empty if none")
    var evidence: String
    @Guide(description: "Cues in a problem that signal this concept applies; empty for plain terms", .maximumCount(3))
    var useWhen: [String]
    @Guide(description: "Look-alike concepts a student might confuse with this one", .maximumCount(3))
    var confusedWith: [String]
    @Guide(description: "true if any part of the definition comes from outside the page")
    var gapFill: Bool
    var confidence: Confidence
}

@Generable enum Kind: String { case term, formula, method, fact }
@Generable enum Confidence: String { case high, medium, low }

let here = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let deck = PDFDocument(url: URL(fileURLWithPath: CommandLine.arguments[1]))!
let instructions = try String(contentsOf: here.appending(path: "prompt.md"), encoding: .utf8)
    .replacingOccurrences(of: "one course document", with: "one page of a course document")

guard SystemLanguageModel.default.isAvailable else {
    print("fm: on-device model unavailable: \(SystemLanguageModel.default.availability)")
    exit(1)
}

let start = Date()
var concepts: [[String: Any]] = []
var failures: [String] = []
for index in 0..<deck.pageCount {
    let text = deck.page(at: index)?.string ?? ""
    let session = LanguageModelSession(model: .default, instructions: instructions)
    do {
        let page = try await session.respond(to: "Page \(index + 1) text:\n\n\(text)", generating: PageConcepts.self).content
        for c in page.concepts {
            concepts.append([
                "title": c.title, "kind": c.kind.rawValue, "definition": c.definition, "slide": index + 1,
                "evidence": c.evidence, "useWhen": c.useWhen, "confusedWith": c.confusedWith,
                "gapFill": c.gapFill, "confidence": c.confidence.rawValue,
            ])
        }
    } catch {
        failures.append("page \(index + 1): \(error)")
    }
}
let seconds = Int(Date().timeIntervalSince(start))
let meta: [String: Any] = ["provider": "Foundation Models on-device (page text only)", "seconds": seconds, "failures": failures]
let data = try JSONSerialization.data(withJSONObject: ["meta": meta, "concepts": concepts], options: [.prettyPrinted, .sortedKeys])
try FileManager.default.createDirectory(at: here.appending(path: "out"), withIntermediateDirectories: true)
try data.write(to: here.appending(path: "out/fm.json"))
print("fm: \(concepts.count) concepts in \(seconds)s, \(failures.count) page failures")
