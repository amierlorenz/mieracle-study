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

    /// Returns the tags with the given names, creating any that don't exist yet.
    ///
    /// Names are trimmed, empty names are dropped, and duplicates collapse.
    public static func resolve(names: [String], in context: ModelContext) throws -> [ConceptTag] {
        let wanted = names.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        var existing = Dictionary(
            try context.fetch(FetchDescriptor<ConceptTag>()).map { ($0.name, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        var result: [ConceptTag] = []
        for name in wanted where !result.contains(where: { $0.name == name }) {
            if let tag = existing[name] {
                result.append(tag)
            } else {
                let tag = ConceptTag(name: name)
                context.insert(tag)
                existing[name] = tag
                result.append(tag)
            }
        }
        return result
    }
}
