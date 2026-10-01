import Foundation

public struct CanvasCourse: Decodable, Hashable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let courseCode: String?

    public init(id: Int, name: String, courseCode: String? = nil) {
        self.id = id
        self.name = name
        self.courseCode = courseCode
    }

    enum CodingKeys: String, CodingKey {
        case id, name, courseCode = "course_code"
    }
}

public struct CanvasAssignment: Decodable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let dueAt: Date?
    public let unlockAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, dueAt = "due_at", unlockAt = "unlock_at"
    }
}

public struct CanvasEvent: Decodable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let startAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, startAt = "start_at"
    }
}
