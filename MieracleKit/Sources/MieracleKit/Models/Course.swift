import Foundation
import SwiftData

/// A class being studied, such as "CS 101". The top of the content hierarchy.
@Model
public final class Course {
    #Index<Course>([\.externalID])

    /// Stable identifier used to match imported content across re-imports.
    public var externalID: String = UUID().uuidString
    public var name: String = ""
    /// The linked Canvas course, when Canvas sync is configured.
    public var canvasCourseID: Int?
    public var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \CourseUnit.course)
    public var units: [CourseUnit]? = []

    @Relationship(deleteRule: .cascade, inverse: \Exam.course)
    public var exams: [Exam]? = []

    public init(externalID: String = UUID().uuidString, name: String) {
        self.externalID = externalID
        self.name = name
    }

    /// Units ordered by ``CourseUnit/sortIndex``.
    public var sortedUnits: [CourseUnit] {
        (units ?? []).sorted { ($0.sortIndex, $0.name) < ($1.sortIndex, $1.name) }
    }
}
