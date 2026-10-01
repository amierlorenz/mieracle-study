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

    func syncIfDue(context: ModelContext) async {
        guard CanvasSync.isDue(lastSync: lastSync) else { return }
        await sync(context: context)
    }

    func sync(context: ModelContext) async {
        guard let client = client(), !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            lastResult = try await CanvasSync(context: context, client: client).run()
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
