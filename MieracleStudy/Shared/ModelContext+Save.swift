import OSLog
import SwiftData

extension ModelContext {
    /// Saves, logging instead of throwing; for UI actions with no recovery path.
    func saveLogging() {
        do {
            try save()
        } catch {
            Logger.app.error("Save failed: \(error)")
        }
    }
}
