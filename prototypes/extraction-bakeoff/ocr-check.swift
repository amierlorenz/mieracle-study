// PROTOTYPE — throwaway. Usage: swift ocr-check.swift <deck.pdf> <provider.json>
// Re-checks quotes that miss the PDF text layer against Vision OCR of the rendered page.
import AppKit
import Foundation
import PDFKit
import Vision

func norm(_ s: String) -> String {
    s.lowercased()
        .replacingOccurrences(of: "[‘’“”]", with: "'", options: .regularExpression)
        .replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespaces)
}

func ocr(_ page: PDFPage) throws -> String {
    let image = page.thumbnail(of: CGSize(width: 2000, height: 2600), for: .mediaBox)
    let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    try VNImageRequestHandler(cgImage: cg).perform([request])
    return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
}

let deck = PDFDocument(url: URL(fileURLWithPath: CommandLine.arguments[1]))!
let json = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))) as! [String: Any]
let concepts = json["concepts"] as! [[String: Any]]
var cache: [Int: (text: String, ocr: String)] = [:]
var counts = ["text": 0, "ocr": 0, "miss": 0, "empty": 0]
for c in concepts {
    let slide = c["slide"] as! Int
    let quote = norm(c["evidence"] as! String)
    guard !quote.isEmpty else { counts["empty", default: 0] += 1; continue }
    guard let page = deck.page(at: slide - 1) else { counts["miss", default: 0] += 1; continue }
    if cache[slide] == nil { cache[slide] = (norm(page.string ?? ""), norm(try ocr(page))) }
    let (text, ocrText) = cache[slide]!
    let result = text.contains(quote) ? "text" : ocrText.contains(quote) ? "ocr" : "miss"
    counts[result, default: 0] += 1
    print("p\(slide) \(result.padding(toLength: 4, withPad: " ", startingAt: 0)) \(c["title"] as! String)")
}
print(counts)
