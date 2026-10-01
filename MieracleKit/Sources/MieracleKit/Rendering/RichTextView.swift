import OSLog
import SwiftUI
import WebKit

/// Displays Markdown with LaTeX math and syntax-highlighted code blocks.
///
/// Inline math uses `$…$` or `\(…\)`; display math uses `$$…$$` or `\[…\]`.
/// Rendering is fully offline, the view sizes itself to its content, and
/// scrolling over it scrolls the surrounding page.
public struct RichTextView: View {
    private let markdown: String

    @State private var renderer: RichTextRenderer?
    @State private var height: CGFloat = 20
    @State private var width: CGFloat = 0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(markdown: String) {
        self.markdown = markdown
    }

    public var body: some View {
        Group {
            if let renderer {
                WebViewHost(webView: renderer.webView)
            } else {
                Color.clear
            }
        }
        .frame(height: height)
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
        .task(id: RenderKey(markdown: markdown, width: width, typeSize: dynamicTypeSize)) {
            await render()
        }
        .accessibilityElement()
        .accessibilityLabel(markdown)
    }

    private var fontSize: Double {
        #if os(macOS)
        NSFont.preferredFont(forTextStyle: .body).pointSize
        #else
        UIFont.preferredFont(forTextStyle: .body).pointSize
        #endif
    }

    private func render() async {
        let renderer = renderer ?? RichTextRenderer()
        self.renderer = renderer
        do {
            let measured = try await renderer.render(markdown: markdown, fontSize: fontSize)
            if measured > 0 { height = measured }
            try await settleHeight(with: renderer)
        } catch is CancellationError {
        } catch {
            Logger.rendering.error("Rendering failed: \(error)")
        }
    }

    /// The web view can still be resizing to its final width when content is
    /// first measured, so re-measure briefly until the height stops changing.
    private func settleHeight(with renderer: RichTextRenderer) async throws {
        var stableCount = 0
        for _ in 0..<10 where stableCount < 2 {
            try await Task.sleep(for: .milliseconds(80))
            let measured = try await renderer.measure()
            guard measured > 0 else { continue }
            if abs(measured - height) < 1 {
                stableCount += 1
            } else {
                stableCount = 0
                height = measured
            }
        }
    }
}

private struct RenderKey: Equatable {
    let markdown: String
    let width: CGFloat
    let typeSize: DynamicTypeSize
}

#if os(macOS)
private struct WebViewHost: NSViewRepresentable {
    let webView: WKWebView
    func makeNSView(context: Context) -> WKWebView { webView }
    func updateNSView(_ view: WKWebView, context: Context) {}
}
#else
private struct WebViewHost: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ view: WKWebView, context: Context) {}
}
#endif

extension Logger {
    static let rendering = Logger(subsystem: "com.mieracle.MieracleStudy", category: "rendering")
}
