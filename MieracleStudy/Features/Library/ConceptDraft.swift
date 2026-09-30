import MieracleKit
import OSLog
import SwiftData

/// Editable copy of a concept's user-facing fields.
struct ConceptDraft {
    var title = ""
    var explanation = ""
    var tagsText = ""
    var resourcesText = ""

    init() {}

    init(concept: Concept) {
        title = concept.title
        explanation = concept.explanation
        tagsText = (concept.tags ?? []).map(\.name).sorted().joined(separator: ", ")
        resourcesText = Resource.format(lines: concept.resources)
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func apply(to concept: Concept, in context: ModelContext) {
        concept.title = title.trimmingCharacters(in: .whitespaces)
        concept.explanation = explanation
        concept.resources = Resource.parse(lines: resourcesText)
        do {
            concept.tags = try ConceptTag.resolve(names: tagsText.components(separatedBy: ","), in: context)
        } catch {
            Logger.app.error("Tag lookup failed: \(error)")
        }
    }
}
