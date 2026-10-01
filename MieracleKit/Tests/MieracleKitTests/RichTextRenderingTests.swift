import Foundation
@testable import MieracleKit
import Testing

@MainActor
struct RichTextRenderingTests {
    @Test(.timeLimit(.minutes(1)))
    func rendersMarkdownMathAndCode() async throws {
        let renderer = RichTextRenderer()
        renderer.webView.frame = CGRect(x: 0, y: 0, width: 400, height: 50)
        let markdown = """
        # Heaps
        Push is $O(\\log n)$ and the sum is $$\\sum_{i=1}^{n} i$$

        ```python
        import heapq
        ```
        """
        let height = try await renderer.render(markdown: markdown, fontSize: 13)
        let html = try await renderer.evaluate("return document.getElementById('content').innerHTML") as? String ?? ""

        #expect(height > 0)
        #expect(html.contains("<h1"))
        #expect(html.contains("katex-display"))
        #expect(html.contains("class=\"katex\""))
        #expect(html.contains("hljs"))
    }
}
