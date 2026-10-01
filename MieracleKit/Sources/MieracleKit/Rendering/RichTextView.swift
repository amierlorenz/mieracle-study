import OSLog
import SwiftUI
import WebKit

/// Displays Markdown with LaTeX math and syntax-highlighted code blocks.
///
/// Inline math uses `$…$` or `\(…\)`; display math uses `$$…$$` or `\[…\]`.
/// Rendering is fully offline, and the view sizes itself to its content.
public struct RichTextView: View {
    private let markdown: String

    @State private var page: WebPage?
    @State private var height: CGFloat = 20
    @State private var width: CGFloat = 0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(markdown: String) {
        self.markdown = markdown
    }

    public var body: some View {
        Group {
            if let page {
                WebView(page)
                    .webViewContentBackground(.hidden)
                    .webViewLinkPreviews(.disabled)
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
        do {
            let page = try await loadedPage()
            let result = try await page.callJavaScript(
                "return render(markdown, fontSize)",
                arguments: ["markdown": markdown, "fontSize": fontSize]
            )
            if let measured = result as? Double, measured > 0 {
                height = measured
            }
            try await settleHeight(of: page)
        } catch is CancellationError {
        } catch {
            Logger.rendering.error("Rendering failed: \(error)")
        }
    }

    /// The web view can still be resizing to its final width when content is
    /// first measured, so re-measure briefly until the height stops changing.
    private func settleHeight(of page: WebPage) async throws {
        var stableCount = 0
        for _ in 0..<10 where stableCount < 2 {
            try await Task.sleep(for: .milliseconds(80))
            guard let measured = try await page.callJavaScript("return measure()") as? Double, measured > 0 else { continue }
            if abs(measured - height) < 1 {
                stableCount += 1
            } else {
                stableCount = 0
                height = measured
            }
        }
    }

    private func loadedPage() async throws -> WebPage {
        if let page { return page }
        let newPage = try await Self.makeLoadedPage()
        page = newPage
        return newPage
    }

    static func makeLoadedPage() async throws -> WebPage {
        var configuration = WebPage.Configuration()
        configuration.urlSchemeHandlers[URLScheme(BundleAssetSchemeHandler.scheme)!] = BundleAssetSchemeHandler()
        let page = WebPage(configuration: configuration, navigationDecider: ExternalLinkDecider())
        for try await _ in page.load(BundleAssetSchemeHandler.templateURL) {}
        return page
    }
}

private struct RenderKey: Equatable {
    let markdown: String
    let width: CGFloat
    let typeSize: DynamicTypeSize
}

extension Logger {
    static let rendering = Logger(subsystem: "com.mieracle.MieracleStudy", category: "rendering")
}
