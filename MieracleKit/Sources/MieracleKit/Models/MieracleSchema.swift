import SwiftData

/// The first versioned schema. New versions are added alongside it with a
/// migration stage in ``MieracleMigrationPlan``.
public enum MieracleSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [
            Course.self,
            CourseUnit.self,
            Concept.self,
            Prompt.self,
            ReviewLog.self,
            ConceptTag.self,
            Exam.self,
            CanvasItem.self,
            SessionPreset.self,
            StudySession.self,
        ]
    }
}

public enum MieracleMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [MieracleSchemaV1.self] }
    public static var stages: [MigrationStage] { [] }
}
