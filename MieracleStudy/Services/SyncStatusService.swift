import CloudKit
import CoreData
import MieracleKit
import Observation

/// Tracks iCloud account status and the most recent sync events, which the
/// CloudKit-backed store reports through Core Data notifications.
@MainActor
@Observable
final class SyncStatusService {
    struct EventSummary: Equatable {
        var kind: String
        var finishedAt: Date?
        var succeeded: Bool
        var errorMessage: String?
    }

    private(set) var accountStatus: CKAccountStatus?
    private(set) var lastImport: EventSummary?
    private(set) var lastExport: EventSummary?
    private(set) var isSyncing = false

    @ObservationIgnored private var observation: (any NSObjectProtocol)?

    func start() {
        guard observation == nil else { return }
        observation = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event else { return }
            let summary = EventSummary(
                kind: event.type == .import ? "import" : event.type == .export ? "export" : "setup",
                finishedAt: event.endDate,
                succeeded: event.succeeded,
                errorMessage: event.error?.localizedDescription
            )
            let type = event.type
            let inProgress = event.endDate == nil
            MainActor.assumeIsolated {
                self?.record(summary, type: type, inProgress: inProgress)
            }
        }
        Task { await refreshAccountStatus() }
    }

    func refreshAccountStatus() async {
        accountStatus = try? await CKContainer(identifier: ModelContainerFactory.cloudKitContainerID).accountStatus()
    }

    private func record(_ summary: EventSummary, type: NSPersistentCloudKitContainer.EventType, inProgress: Bool) {
        isSyncing = inProgress
        guard !inProgress else { return }
        switch type {
        case .import: lastImport = summary
        case .export: lastExport = summary
        default: break
        }
    }
}
