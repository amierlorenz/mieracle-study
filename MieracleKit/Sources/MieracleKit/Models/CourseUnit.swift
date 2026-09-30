import Foundation
import SwiftData

/// A unit within a course, grouping related concepts.
///
/// Named `CourseUnit` to avoid clashing with Foundation's `Unit`.
@Model
public final class CourseUnit {
    #Index<CourseUnit>([\.externalID])

    public var externalID: String = UUID().uuidString
    public var name: String = ""
    public var sortIndex: Int = 0

    public var course: Course?

    @Relationship(deleteRule: .cascade, inverse: \Concept.unit)
    public var concepts: [Concept]? = []

    /// Exams that cover this unit.
    public var exams: [Exam]? = []

    public init(externalID: String = UUID().uuidString, name: String, sortIndex: Int = 0) {
        self.externalID = externalID
        self.name = name
        self.sortIndex = sortIndex
    }
}
