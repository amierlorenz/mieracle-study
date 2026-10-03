// Throwaway benchmark: PDFKit text layer + Vision OCR per page at several render scales.
// Usage: ocrbench <file.pdf> <pageCount> <scale> <api: new|legacy> [level: accurate|fast]
import AppKit
import Foundation
import PDFKit
import Vision

func maxRSSMB() -> Double {
    var usage = rusage()
    getrusage(RUSAGE_SELF, &usage)
    return Double(usage.ru_maxrss) / 1_048_576
}

func render(_ page: PDFPage, scale: CGFloat) -> CGImage {
    let box = page.bounds(for: .mediaBox)
    let w = Int(box.width * scale), h = Int(box.height * scale)
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.setFillColor(.white)
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    ctx.scaleBy(x: scale, y: scale)
    page.draw(with: .mediaBox, to: ctx)
    return ctx.makeImage()!
}

func ocrLegacy(_ image: CGImage, accurate: Bool) throws -> (String, Float) {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = accurate ? .accurate : .fast
    request.usesLanguageCorrection = true
    try VNImageRequestHandler(cgImage: image).perform([request])
    let obs = request.results ?? []
    let conf = obs.isEmpty ? 0 : obs.map { $0.topCandidates(1).first?.confidence ?? 0 }.reduce(0, +) / Float(obs.count)
    return (obs.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n"), conf)
}

func ocrNew(_ image: CGImage, accurate: Bool) async throws -> (String, Float) {
    var request = RecognizeTextRequest()
    request.recognitionLevel = accurate ? .accurate : .fast
    request.usesLanguageCorrection = true
    let obs = try await request.perform(on: image)
    let conf = obs.isEmpty ? 0 : obs.map { $0.topCandidates(1).first?.confidence ?? 0 }.reduce(0, +) / Float(obs.count)
    return (obs.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n"), conf)
}

let args = CommandLine.arguments
let doc = PDFDocument(url: URL(fileURLWithPath: args[1]))!
let pages = min(Int(args[2])!, doc.pageCount)
let scale = CGFloat(Double(args[3])!)
let api = args[4]
let accurate = args.count < 6 || args[5] == "accurate"
let outDir = URL(fileURLWithPath: args[1]).deletingLastPathComponent()
    .appendingPathComponent(URL(fileURLWithPath: args[1]).deletingPathExtension().lastPathComponent + "-ocr-\(api)-\(args[3])x-\(accurate ? "acc" : "fast")")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

var textTime = 0.0, renderTime = 0.0, ocrTime = 0.0
let clock = ContinuousClock()
for i in 0..<pages {
    let page = doc.page(at: i)!
    var t = clock.now
    let layer = page.string ?? ""
    textTime += (clock.now - t) / .seconds(1)
    t = clock.now
    let image = render(page, scale: scale)
    renderTime += (clock.now - t) / .seconds(1)
    t = clock.now
    let (text, conf) = api == "new" ? try await ocrNew(image, accurate: accurate) : try ocrLegacy(image, accurate: accurate)
    ocrTime += (clock.now - t) / .seconds(1)
    try text.write(to: outDir.appendingPathComponent("p\(i + 1).txt"), atomically: true, encoding: .utf8)
    try layer.write(to: outDir.appendingPathComponent("p\(i + 1).layer.txt"), atomically: true, encoding: .utf8)
    print("p\(i + 1) layerChars=\(layer.count) ocrChars=\(text.count) conf=\(String(format: "%.2f", conf)) px=\(image.width)x\(image.height)")
}
print(String(format: "pages=%d scale=%.1f api=%@ level=%@ text=%.2fs render=%.2fs ocr=%.2fs perPageOCR=%.2fs maxRSS=%.0fMB",
             pages, scale, api, accurate ? "accurate" : "fast", textTime, renderTime, ocrTime, ocrTime / Double(pages), maxRSSMB()))
