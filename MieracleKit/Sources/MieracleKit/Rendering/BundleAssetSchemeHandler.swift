import Foundation
import UniformTypeIdentifiers
import WebKit

/// Serves the bundled rendering assets over the `mieracle:` scheme so the
/// template can load scripts, styles, and fonts without file-system access.
struct BundleAssetSchemeHandler: URLSchemeHandler {
    static let scheme = "mieracle"
    static let templateURL = URL(string: "\(scheme)://assets/template.html")!

    func reply(for request: URLRequest) -> AsyncThrowingStream<URLSchemeTaskResult, any Error> {
        AsyncThrowingStream { continuation in
            guard let url = request.url, let data = Self.asset(at: url.path()) else {
                continuation.finish(throwing: URLError(.fileDoesNotExist))
                return
            }
            let response = URLResponse(url: url, mimeType: Self.mimeType(for: url), expectedContentLength: data.count, textEncodingName: "utf-8")
            continuation.yield(.response(response))
            continuation.yield(.data(data))
            continuation.finish()
        }
    }

    private static func asset(at path: String) -> Data? {
        guard let root = Bundle.module.resourceURL?.appending(path: "Web", directoryHint: .isDirectory) else { return nil }
        let file = root.appending(path: path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))).standardizedFileURL
        guard file.path().hasPrefix(root.standardizedFileURL.path()) else { return nil }
        return try? Data(contentsOf: file)
    }

    private static func mimeType(for url: URL) -> String {
        UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }
}
