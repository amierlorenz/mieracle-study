import Foundation
import Synchronization

/// Serves canned responses keyed by URL path, and records requests.
final class StubURLProtocol: URLProtocol {
    struct Response: Sendable {
        var status = 200
        var body: String
        var headers: [String: String] = [:]
    }

    static let responses = Mutex<[String: Response]>([:])
    static let requests = Mutex<[URLRequest]>([])

    static func session(_ responses: [String: Response]) -> URLSession {
        Self.responses.withLock { $0 = responses }
        Self.requests.withLock { $0 = [] }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.withLock { $0.append(request) }
        let url = request.url!
        let key = url.query().map { "\(url.path())?\($0)" } ?? url.path()
        let stub = Self.responses.withLock { $0[key] ?? $0[url.path()] } ?? Response(status: 404, body: "[]")
        let response = HTTPURLResponse(url: url, statusCode: stub.status, httpVersion: nil, headerFields: stub.headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(stub.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
