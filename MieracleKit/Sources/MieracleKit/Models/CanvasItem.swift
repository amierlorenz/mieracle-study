import Foundation
import SwiftData

/// An assignment or calendar event fetched from Canvas, cached so the user can
/// mark which ones are exams.
@Model
public final class CanvasItem {
    #Index<CanvasItem>([\.canvasID])

    /// Canvas identifier, prefixed by kind (for example `assignment_123`).
    public var canvasID: String = ""
    public var canvasCourseID: Int = 0
    public var name: String = ""
    public var kindRaw: String = CanvasItemKind.assignment.rawValue
    public var dueAt: Date?
    /// When the item opens to students (Canvas `unlock_at`).
    public var unlockAt: Date?
    public var isExam: Bool = false
    /// Hidden from exam suggestions.
    public var isDismissed: Bool = false
    /// Turned in on Canvas, as of the last sync.
    public var isSubmitted: Bool = false
    /// Marked done in the app, for work Canvas doesn't track as a submission.
    public var isMarkedDone: Bool = false
    /// The item's page in Canvas, as reported by the API.
    public var htmlURL: String?
    public var lastSyncedAt: Date = Date.now

    public init(canvasID: String, canvasCourseID: Int, name: String, kind: CanvasItemKind, dueAt: Date?) {
        self.canvasID = canvasID
        self.canvasCourseID = canvasCourseID
        self.name = name
        self.kindRaw = kind.rawValue
        self.dueAt = dueAt
    }

    public var kind: CanvasItemKind { CanvasItemKind(rawValue: kindRaw) ?? .assignment }

    /// The item's Canvas page: the stored link, or one built from the Canvas
    /// address for items synced before links were stored.
    public func webURL(canvasBaseURL: URL?) -> URL? {
        if let htmlURL, let url = URL(string: htmlURL) { return url }
        guard let canvasBaseURL, let id = canvasID.split(separator: "_").last else { return nil }
        let path = kind == .assignment ? "courses/\(canvasCourseID)/assignments/\(id)" : "calendar?event_id=\(id)"
        return URL(string: path, relativeTo: canvasBaseURL)?.absoluteURL
    }
}

public enum CanvasItemKind: String, Codable, Sendable {
    case assignment
    case event
}
