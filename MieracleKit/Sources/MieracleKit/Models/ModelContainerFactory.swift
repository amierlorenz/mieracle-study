import SwiftData

/// Builds the app's model container.
public enum ModelContainerFactory {
    /// The CloudKit container shared by the Mac and iPhone apps.
    public static let cloudKitContainerID = "iCloud.com.mieracle.MieracleStudy"

    public enum Storage: Sendable {
        /// On-disk store mirrored to the CloudKit private database.
        case cloudSynced
        /// On-disk store with no sync.
        case local
        /// Throwaway store for tests and previews.
        case inMemory
    }

    public static func make(storage: Storage) throws -> ModelContainer {
        let schema = Schema(versionedSchema: MieracleSchemaV1.self)
        let configuration = switch storage {
        case .cloudSynced:
            ModelConfiguration(schema: schema, cloudKitDatabase: .private(cloudKitContainerID))
        case .local:
            ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        case .inMemory:
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, migrationPlan: MieracleMigrationPlan.self, configurations: configuration)
    }
}
