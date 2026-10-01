import Foundation

/// Reads courses, assignments, and calendar events from the Canvas REST API.
public struct CanvasClient: Sendable {
    public let baseURL: URL
    private let token: String
    private let session: URLSession

    public init(baseURL: URL, token: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
    }

    public enum ClientError: Error, Equatable {
        case unauthorized
        case http(Int)
        case invalidResponse
    }

    public func activeCourses() async throws -> [CanvasCourse] {
        try await getAll("api/v1/courses", query: [URLQueryItem(name: "enrollment_state", value: "active")])
    }

    public func assignments(courseID: Int) async throws -> [CanvasAssignment] {
        try await getAll("api/v1/courses/\(courseID)/assignments")
    }

    public func events(courseID: Int) async throws -> [CanvasEvent] {
        try await getAll("api/v1/calendar_events", query: [
            URLQueryItem(name: "context_codes[]", value: "course_\(courseID)"),
            URLQueryItem(name: "type", value: "event"),
            URLQueryItem(name: "all_events", value: "true"),
        ])
    }

    /// Follows `Link: <…>; rel="next"` headers until every page is read.
    func getAll<Item: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> [Item] {
        var next: URL? = baseURL.appending(path: path).appending(queryItems: query + [URLQueryItem(name: "per_page", value: "100")])
        var items: [Item] = []
        while let url = next {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw ClientError.invalidResponse }
            switch http.statusCode {
            case 200..<300: break
            case 401: throw ClientError.unauthorized
            default: throw ClientError.http(http.statusCode)
            }
            items += try Self.decoder.decode([Item].self, from: data)
            next = Self.nextPage(from: http.value(forHTTPHeaderField: "Link"))
        }
        return items
    }

    static func nextPage(from linkHeader: String?) -> URL? {
        guard let linkHeader else { return nil }
        for part in linkHeader.split(separator: ",") where part.contains("rel=\"next\"") {
            guard let start = part.firstIndex(of: "<"), let end = part.firstIndex(of: ">") else { continue }
            return URL(string: String(part[part.index(after: start)..<end]))
        }
        return nil
    }

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
