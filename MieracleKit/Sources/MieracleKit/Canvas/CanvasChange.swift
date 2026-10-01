import Foundation

/// Something that changed in Canvas since the previous sync, kept so the
/// user can see what moved, appeared, or disappeared.
public struct CanvasChange: Codable, Hashable, Sendable, Identifiable {
    public enum Kind: String, Codable, Sendable {
        case added
        case removed
        case rescheduled
    }

    public var kind: Kind
    public var canvasID: String
    public var canvasCourseID: Int
    public var name: String
    public var oldDate: Date?
    public var newDate: Date?
    /// Whether the item is linked to one of the user's exams.
    public var isExam: Bool
    public var detectedAt: Date

    public var id: String { "\(kind.rawValue)-\(canvasID)-\(detectedAt.timeIntervalSince1970)" }

    public init(kind: Kind, canvasID: String, canvasCourseID: Int, name: String, oldDate: Date?, newDate: Date?, isExam: Bool, detectedAt: Date) {
        self.kind = kind
        self.canvasID = canvasID
        self.canvasCourseID = canvasCourseID
        self.name = name
        self.oldDate = oldDate
        self.newDate = newDate
        self.isExam = isExam
        self.detectedAt = detectedAt
    }
}
