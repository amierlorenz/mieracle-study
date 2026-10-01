import SwiftData

/// Deletes every record in the store. With iCloud sync on, the deletions sync
/// to the user's other devices too.
public enum DataReset {
    @MainActor
    public static func deleteAll(in context: ModelContext) throws {
        try context.delete(model: ReviewLog.self)
        try context.delete(model: Prompt.self)
        try context.delete(model: Concept.self)
        try context.delete(model: CourseUnit.self)
        try context.delete(model: Exam.self)
        try context.delete(model: Course.self)
        try context.delete(model: ConceptTag.self)
        try context.delete(model: CanvasItem.self)
        try context.delete(model: SessionPreset.self)
        try context.delete(model: StudySession.self)
        try context.save()
    }
}
