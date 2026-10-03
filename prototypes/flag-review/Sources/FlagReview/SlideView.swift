// PROTOTYPE — throwaway. Renders a deck page and highlights the OCR lines that match a quote.
import AppKit
import PDFKit
import SwiftUI
import Vision

struct OCRLine {
    var words: [String]
    var box: CGRect
}

final class SlideCache: @unchecked Sendable {
    static let shared = SlideCache()
    var deck: PDFDocument?
    private var images: [Int: NSImage] = [:]
    private var lines: [Int: [OCRLine]] = [:]
    private let lock = NSLock()

    var pageCount: Int { deck?.pageCount ?? 0 }

    @MainActor func image(_ page: Int) -> NSImage? {
        if let image = images[page] { return image }
        guard let pdfPage = deck?.page(at: page - 1) else { return nil }
        let image = pdfPage.thumbnail(of: CGSize(width: 1600, height: 2000), for: .mediaBox)
        images[page] = image
        return image
    }

    func lines(_ page: Int, _ cg: CGImage) -> [OCRLine] {
        lock.lock(); defer { lock.unlock() }
        if let found = lines[page] { return found }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        try? VNImageRequestHandler(cgImage: cg).perform([request])
        let found: [OCRLine] = (request.results ?? []).compactMap { obs in
            guard let text = obs.topCandidates(1).first?.string else { return nil }
            return OCRLine(words: words(text), box: obs.boundingBox)
        }
        lines[page] = found
        return found
    }
}

func words(_ s: String) -> [String] {
    s.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 1 }
}

func matches(_ line: OCRLine, _ quote: String) -> Bool {
    let qWords = words(quote)
    guard line.words.count >= 2, !qWords.isEmpty else { return false }
    let q = " " + qWords.joined(separator: " ") + " "
    let l = " " + line.words.joined(separator: " ") + " "
    if line.words.count >= 4, q.contains(l) || l.contains(q) { return true }
    let set = Set(qWords)
    return line.words.count >= 5 && Double(line.words.filter(set.contains).count) / Double(line.words.count) >= 0.8
}

struct SlideView: View {
    var page: Int
    var quotes: [String]
    @State private var loaded: (image: NSImage, lines: [OCRLine])?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let loaded {
                let hits = loaded.lines.filter { line in quotes.contains { matches(line, $0) } }
                Image(nsImage: loaded.image)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        GeometryReader { geo in
                            ForEach(Array(hits.enumerated()), id: \.offset) { _, line in
                                Rectangle()
                                    .fill(.yellow.opacity(0.35))
                                    .border(.orange)
                                    .frame(width: line.box.width * geo.size.width, height: line.box.height * geo.size.height)
                                    .position(x: line.box.midX * geo.size.width, y: (1 - line.box.midY) * geo.size.height)
                            }
                        }
                    }
                    .border(.separator)
                let wanted = quotes.filter { !$0.isEmpty }
                Text(wanted.isEmpty ? "Slide \(page) · no quote to find"
                     : hits.isEmpty ? "Slide \(page) · quote not found by OCR (formula or image text?)"
                     : "Slide \(page) · \(hits.count) matching line\(hits.count == 1 ? "" : "s") highlighted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if SlideCache.shared.deck == nil {
                ContentUnavailableView("No deck", systemImage: "doc", description: Text("Pass --deck <pdf> to see slides."))
            } else {
                ProgressView("Reading slide \(page)…").frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .task(id: page) {
            loaded = nil
            let p = page
            guard let image = SlideCache.shared.image(p), let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
            try? await Task.sleep(for: .milliseconds(50))
            let found = SlideCache.shared.lines(p, cg)
            loaded = (image, found)
        }
    }
}
