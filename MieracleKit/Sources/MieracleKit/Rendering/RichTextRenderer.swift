import Foundation
import WebKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Owns one web view that renders Markdown, math, and code from the bundled
/// template, and reports the rendered height.
@MainActor
final class RichTextRenderer: NSObject, WKNavigationDelegate {
    let webView: WKWebView
    private var isLoaded = false
    private var loadWaiters: [CheckedContinuation<Void, Never>] = []

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(RichTextAssets(), forURLScheme: RichTextAssets.scheme)
        webView = PassthroughWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        #if os(macOS)
        webView.setValue(false, forKey: "drawsBackground")
        #else
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.backgroundColor = .clear
        #endif
        webView.load(URLRequest(url: RichTextAssets.templateURL))
    }

    /// Renders and returns the content height in points.
    func render(markdown: String, fontSize: Double) async throws -> Double {
        await waitUntilLoaded()
        let result = try await webView.callAsyncJavaScript(
            "return render(markdown, fontSize)",
            arguments: ["markdown": markdown, "fontSize": fontSize],
            contentWorld: .page
        )
        return result as? Double ?? 0
    }

    func measure() async throws -> Double {
        await waitUntilLoaded()
        return try await webView.callAsyncJavaScript("return measure()", contentWorld: .page) as? Double ?? 0
    }

    func evaluate(_ script: String) async throws -> Any? {
        await waitUntilLoaded()
        return try await webView.callAsyncJavaScript(script, contentWorld: .page)
    }

    private func waitUntilLoaded() async {
        guard !isLoaded else { return }
        await withCheckedContinuation { loadWaiters.append($0) }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoaded = true
        loadWaiters.forEach { $0.resume() }
        loadWaiters = []
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = action.request.url, url.scheme != RichTextAssets.scheme else { return .allow }
        if action.navigationType == .linkActivated, ["http", "https", "mailto"].contains(url.scheme) {
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #else
            await UIApplication.shared.open(url)
            #endif
        }
        return .cancel
    }
}

/// A web view that never keeps scroll gestures for itself: content is sized to
/// fit, so scrolling over it should move the surrounding page.
final class PassthroughWebView: WKWebView {
    #if os(macOS)
    override func scrollWheel(with event: NSEvent) {
        nextResponder?.scrollWheel(with: event)
    }
    #endif
}
