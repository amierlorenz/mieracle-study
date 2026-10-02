import Foundation

/// Keeps study settings the same on every device by mirroring them through
/// iCloud's key-value store. Device-specific values (the Python path, sync
/// times) stay local.
@MainActor
final class SettingsSync {
    static let syncedKeys = [
        SettingsKey.dailyNewLimit,
        SettingsKey.asksConfidence,
        SettingsKey.blursChoices,
        SettingsKey.aiModel,
        SettingsKey.canvasBaseURL,
    ]

    private let cloud = NSUbiquitousKeyValueStore.default
    private let defaults = UserDefaults.standard
    private var observers: [any NSObjectProtocol] = []
    private var isApplyingCloudChanges = false

    func start() {
        guard observers.isEmpty else { return }
        observers.append(NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud, queue: .main
        ) { [weak self] notification in
            let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
            MainActor.assumeIsolated { self?.pullFromCloud(keys: keys) }
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: defaults, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.pushToCloud() }
        })
        cloud.synchronize()
        pullFromCloud(keys: nil)
        pushToCloud()
    }

    /// Copies cloud values into local settings; the cloud wins for keys it has.
    private func pullFromCloud(keys: [String]?) {
        isApplyingCloudChanges = true
        defer { isApplyingCloudChanges = false }
        for key in keys ?? Self.syncedKeys where Self.syncedKeys.contains(key) {
            if let value = cloud.object(forKey: key) {
                defaults.set(value, forKey: key)
            }
        }
    }

    /// Copies local settings the cloud doesn't have yet, or that changed here.
    private func pushToCloud() {
        guard !isApplyingCloudChanges else { return }
        for key in Self.syncedKeys {
            guard let value = defaults.object(forKey: key) else { continue }
            if !(cloud.object(forKey: key) as AnyObject).isEqual(value) {
                cloud.set(value, forKey: key)
            }
        }
    }
}
