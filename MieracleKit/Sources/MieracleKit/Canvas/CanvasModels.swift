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
    public struct Submission: Decodable, Hashable, Sendable {
        public let workflowState: String?

        enum CodingKeys: String, CodingKey {
            case workflowState = "workflow_state"
        }
    }

    public let id: Int
    public let name: String
    public let dueAt: Date?
    public let unlockAt: Date?
    public let submission: Submission?
    /// The assignment's page in Canvas.
    public let htmlURL: URL?

    enum CodingKeys: String, CodingKey {
        case id, name, submission, dueAt = "due_at", unlockAt = "unlock_at", htmlURL = "html_url"
    }

    /// Whether the student has turned it in (or it's already graded).
    public var isSubmitted: Bool {
        ["submitted", "graded", "pending_review"].contains(submission?.workflowState ?? "")
    }
}

public struct CanvasEvent: Decodable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let startAt: Date?
    public let htmlURL: URL?

    enum CodingKeys: String, CodingKey {
        case id, title, startAt = "start_at", htmlURL = "html_url"
    }
}
