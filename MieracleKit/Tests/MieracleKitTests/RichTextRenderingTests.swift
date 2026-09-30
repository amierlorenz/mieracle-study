import Foundation
@testable import MieracleKit
import Testing
import WebKit

@MainActor
struct RichTextRenderingTests {
    @Test func rendersMarkdownMathAndCode() async throws {
        let page = try await RichTextView.makeLoadedPage()
        let markdown = """
        # Heaps
        Push is $O(\\log n)$ and the sum is $$\\sum_{i=1}^{n} i$$

        ```python
        import heapq
        ```
        """
        let height = try await page.callJavaScript("return render(markdown, 13)", arguments: ["markdown": markdown]) as? Double
        let html = try await page.callJavaScript("return document.getElementById('content').innerHTML") as? String ?? ""

        #expect((height ?? 0) > 0)
        #expect(html.contains("<h1"))
        #expect(html.contains("katex-display"))
        #expect(html.contains("class=\"katex\""))
        #expect(html.contains("hljs"))
    }
}
