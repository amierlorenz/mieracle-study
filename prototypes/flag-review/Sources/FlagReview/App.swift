// PROTOTYPE — throwaway. Three variants of the Extract flag-review screen (issue #80).
// swift run FlagReview [--variant A|B|C] [--deck <pdf>] [--candidates <gemini.json>]
// Defaults point at the extraction bake-off outputs, which stay local (course material, not committed).
import AppKit
import PDFKit
import SwiftUI

enum Args {
    static func value(_ name: String) -> String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
    static let bakeoffOutput = ".claude/worktrees/prototype-extraction-bakeoff/prototypes/extraction-bakeoff/out/gemini.json"
    static let candidates = value("--candidates") ?? {
        var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        while dir.path != "/" {
            let candidate = dir.appending(path: bakeoffOutput)
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate.path }
            dir = dir.deletingLastPathComponent()
        }
        return bakeoffOutput
    }()
    static let deck = value("--deck") ?? NSHomeDirectory() + "/Downloads/Chapter 3 sections 3.1-3.3.pdf"
    static let variant = ["A": 0, "B": 1, "C": 2][value("--variant")?.uppercased() ?? "A"] ?? 0
}

@main
struct FlagReviewApp: App {
    @State private var store: ReviewStore?
    @State private var error: String?
    @State private var variant = Args.variant

    init() {
        SlideCache.shared.deck = PDFDocument(url: URL(fileURLWithPath: Args.deck))
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate()
        }
    }

    var body: some Scene {
        WindowGroup("Review extraction — PROTOTYPE") {
            Group {
                if let store {
                    ZStack(alignment: .bottom) {
                        switch variant {
                        case 0: VariantA()
                        case 1: VariantB()
                        default: VariantC()
                        }
                        VariantSwitcher(variant: $variant)
                    }
                    .environment(store)
                } else {
                    ContentUnavailableView("Couldn't load candidates", systemImage: "exclamationmark.triangle", description: Text(error ?? Args.candidates))
                }
            }
            .frame(minWidth: 1200, minHeight: 760)
            .task {
                do { store = try SampleData.load(from: URL(fileURLWithPath: Args.candidates)) } catch { self.error = "\(Args.candidates): \(error)" }
                if let path = Args.value("--snapshot") {
                    try? await Task.sleep(for: .seconds(6))
                    if let view = NSApplication.shared.windows.first(where: \.isVisible)?.contentView,
                       let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                        view.cacheDisplay(in: view.bounds, to: rep)
                        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
                    }
                    exit(0)
                }
            }
        }
        .defaultSize(width: 1600, height: 1000)
    }
}
