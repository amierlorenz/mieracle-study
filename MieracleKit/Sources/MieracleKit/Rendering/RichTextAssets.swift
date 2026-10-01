import Foundation
import UniformTypeIdentifiers
import WebKit

/// Serves the bundled rendering assets over the `mieracle:` scheme so the
/// template can load scripts, styles, and fonts without file-system access.
final class RichTextAssets: NSObject, WKURLSchemeHandler {
    static let scheme = "mieracle"
    static let templateURL = URL(string: "\(scheme)://assets/template.html")!

    func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
        guard let url = task.request.url, let data = Self.asset(at: url.path()) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }
        let mimeType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        task.didReceive(URLResponse(url: url, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: "utf-8"))
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {}

    private static func asset(at path: String) -> Data? {
        guard let root = Bundle.module.resourceURL?.appending(path: "Web", directoryHint: .isDirectory) else { return nil }
        let file = root.appending(path: path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))).standardizedFileURL
        guard file.path().hasPrefix(root.standardizedFileURL.path()) else { return nil }
        return try? Data(contentsOf: file)
    }
}
