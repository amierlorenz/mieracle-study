import MieracleKit
import Observation

/// Shared navigation state, so one screen can open another, such as the
/// dashboard starting a study session.
@MainActor
@Observable
final class AppNavigation {
    var selection: SidebarSection? = .dashboard
    /// A session another screen asked the Study screen to start.
    var pendingSession: SessionConfig?

    func startSession(_ config: SessionConfig) {
        pendingSession = config
        selection = .study
    }
}
