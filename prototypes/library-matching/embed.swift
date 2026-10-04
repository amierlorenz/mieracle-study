// PROTOTYPE — throwaway. Usage: swift embed.swift  → out/embeddings.json
// Option A, on-device: cosine similarity of title + definition, with two Natural Language models.
import Foundation
import NaturalLanguage

let out = URL(fileURLWithPath: "out")
func load(_ name: String) -> Any { try! JSONSerialization.jsonObject(with: Data(contentsOf: out.appending(path: name))) }

func clean(_ s: String) -> String {
    String(s.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "`", with: "").replacingOccurrences(of: "$", with: "").prefix(400))
}

let library = (load("library.json") as! [[String: Any]]).map { (id: $0["id"] as! String, text: clean("\($0["title"]!): \($0["explanation"]!)")) }
let decks = ["mis", "mat305", "os7", "os8"]

let sentence = NLEmbedding.sentenceEmbedding(for: .english)!
let contextual = NLContextualEmbedding(language: .english)!
if !contextual.hasAvailableAssets {
    let done = DispatchSemaphore(value: 0)
    contextual.requestAssets { r, e in print("assets:", r.rawValue, e as Any); done.signal() }
    done.wait()
}
try contextual.load()

func normalize(_ v: [Double]) -> [Double] { let n = sqrt(v.reduce(0) { $0 + $1 * $1 }); return v.map { $0 / max(n, 1e-9) } }
func dot(_ a: [Double], _ b: [Double]) -> Double { zip(a, b).reduce(0) { $0 + $1.0 * $1.1 } }
func sentenceVec(_ s: String) -> [Double] { normalize(sentence.vector(for: s) ?? []) }
func contextualVec(_ s: String) -> [Double] {
    let r = try! contextual.embeddingResult(for: s, language: .english)
    var sum = [Double](repeating: 0, count: contextual.dimension), n = 0.0
    r.enumerateTokenVectors(in: s.startIndex..<s.endIndex) { v, _ in
        for i in v.indices { sum[i] += v[i] }; n += 1; return true
    }
    return normalize(sum.map { $0 / max(n, 1) })
}

let models: [(String, (String) -> [Double])] = [("sentence", sentenceVec), ("contextual", contextualVec)]
var result: [String: Any] = [:]
let clock = ContinuousClock()
for (name, embed) in models {
    let start = clock.now
    let lib = library.map { embed($0.text) }
    var perDeck: [String: Any] = [:]
    for deck in decks {
        let concepts = (load("\(deck)-extract.json") as! [String: Any])["concepts"] as! [[String: Any]]
        perDeck[deck] = concepts.map { c -> [String: Double] in
            let v = embed(clean("\(c["title"]!): \(c["definition"]!)"))
            return Dictionary(uniqueKeysWithValues: zip(library.map(\.id), lib.map { (dot(v, $0) * 1000).rounded() / 1000 }))
        }
    }
    result[name] = ["seconds": "\(clock.now - start)", "scores": perDeck]
    print(name, clock.now - start)
}
try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]).write(to: out.appending(path: "embeddings.json"))
