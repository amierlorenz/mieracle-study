import Foundation
import SwiftData

/// A label that cuts across units, such as "exam 2" or "recursion".
@Model
public final class ConceptTag {
    #Index<ConceptTag>([\.name])

    public var name: String = ""

    public var concepts: [Concept]? = []
    public var exams: [Exam]? = []

    public init(name: String) {
        self.name = name
    }
}
