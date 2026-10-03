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
    return line.words.count >= 5 && Double(line.words.filter(set.contains).count) / Double(line.words.count) >= 0.9
}

struct SlideQuote {
    var owner: String
    var text: String
}

struct SlideView: View {
    var page: Int
    var quotes: [SlideQuote]
    var focused: String? = nil
    var onTap: ((String) -> Void)? = nil
    @State private var loaded: (image: NSImage, lines: [OCRLine])?

    init(page: Int, quotes: [String]) {
        self.page = page
        self.quotes = quotes.map { SlideQuote(owner: $0, text: $0) }
    }

    init(page: Int, quotes: [SlideQuote], focused: String?, onTap: @escaping (String) -> Void) {
        self.page = page
        self.quotes = quotes
        self.focused = focused
        self.onTap = onTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let loaded {
                let hits: [(owner: String, box: CGRect)] = loaded.lines.compactMap { line in
                    quotes.first { matches(line, $0.text) }.map { ($0.owner, line.box) }
                }
                Image(nsImage: loaded.image)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        GeometryReader { geo in
                            ForEach(Array(hits.enumerated()), id: \.offset) { _, hit in
                                let strong = focused == nil || focused == hit.owner
                                Rectangle()
                                    .fill(.yellow.opacity(strong ? 0.4 : 0.08))
                                    .border(strong ? Color.orange : Color.orange.opacity(0.3), width: focused == hit.owner ? 2 : 1)
                                    .contentShape(.rect)
                                    .onTapGesture { onTap?(hit.owner) }
                                    .help(onTap == nil ? "" : "Show the concept this quote supports")
                                    .frame(width: hit.box.width * geo.size.width, height: hit.box.height * geo.size.height)
                                    .position(x: hit.box.midX * geo.size.width, y: (1 - hit.box.midY) * geo.size.height)
                            }
                        }
                    }
                    .border(.separator)
                let focusedQuote = quotes.first { $0.owner == focused && !$0.text.isEmpty }
                let focusedHits = hits.filter { $0.owner == focused }.count
                Text(focused != nil && focusedQuote == nil ? "Slide \(page) · this concept has no quote to find"
                     : focused != nil && focusedHits == 0 ? "Slide \(page) · its quote wasn't found by OCR (formula or image text?): check the slide by eye"
                     : quotes.allSatisfy { $0.text.isEmpty } ? "Slide \(page) · no quote to find"
                     : hits.isEmpty ? "Slide \(page) · quote not found by OCR (formula or image text?)"
                     : "Slide \(page) · \(hits.count) matching line\(hits.count == 1 ? "" : "s") highlighted" + (onTap == nil ? "" : " · click one to find its concept"))
                    .font(.caption)
                    .foregroundStyle(focused != nil && focusedQuote != nil && focusedHits == 0 ? .orange : .secondary)
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
