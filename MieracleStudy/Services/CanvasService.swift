import Foundation
import MieracleKit
import Observation
import OSLog
import SwiftData

/// Owns Canvas configuration and sync state for the app.
@MainActor
@Observable
final class CanvasService {
    private(set) var isSyncing = false
    private(set) var lastResult: CanvasSync.Result?
    private(set) var errorMessage: String?
    /// Changes found by syncs that the user hasn't dismissed yet.
    private(set) var pendingChanges: [CanvasChange] = CanvasService.loadPendingChanges()

    /// A client built from Settings and the Keychain, or `nil` if Canvas isn't set up.
    func client() -> CanvasClient? {
        let base = UserDefaults.standard.string(forKey: SettingsKey.canvasBaseURL) ?? ""
        guard let url = URL(string: base.trimmingCharacters(in: .whitespaces)), url.scheme == "https",
              let token = try? KeychainStore.canvasToken.read(), !token.isEmpty else { return nil }
        return CanvasClient(baseURL: url, token: token)
    }

    var lastSync: Date? {
        let value = UserDefaults.standard.double(forKey: SettingsKey.canvasLastSync)
        return value == 0 ? nil : Date(timeIntervalSince1970: value)
    }

    func dismissChanges() {
        pendingChanges = []
        savePendingChanges()
    }

    func dismiss(_ change: CanvasChange) {
        pendingChanges.removeAll { $0.id == change.id }
        savePendingChanges()
    }

    private static func loadPendingChanges() -> [CanvasChange] {
        guard let data = UserDefaults.standard.data(forKey: SettingsKey.canvasPendingChanges) else { return [] }
        return (try? JSONDecoder().decode([CanvasChange].self, from: data)) ?? []
    }

    private func savePendingChanges() {
        UserDefaults.standard.set(try? JSONEncoder().encode(pendingChanges), forKey: SettingsKey.canvasPendingChanges)
    }

    func syncIfDue(context: ModelContext) async {
        guard CanvasSync.isDue(lastSync: lastSync) else { return }
        await sync(context: context)
    }

    func sync(context: ModelContext) async {
        guard let client = client(), !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let result = try await CanvasSync(context: context, client: client).run()
            lastResult = result
            if !result.changes.isEmpty {
                pendingChanges = (pendingChanges + result.changes).sorted { ($0.isExam ? 0 : 1, $0.newDate ?? $0.oldDate ?? .distantFuture) < ($1.isExam ? 0 : 1, $1.newDate ?? $1.oldDate ?? .distantFuture) }
                savePendingChanges()
            }
            UserDefaults.standard.set(Date.now.timeIntervalSince1970, forKey: SettingsKey.canvasLastSync)
            errorMessage = nil
        } catch CanvasClient.ClientError.unauthorized {
            errorMessage = "Canvas rejected the token. Create a new one in Settings."
        } catch {
            Logger.app.error("Canvas sync failed: \(error)")
            errorMessage = "Canvas sync failed: \(error.localizedDescription)"
        }
    }
}
