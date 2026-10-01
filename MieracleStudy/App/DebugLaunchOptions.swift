#if DEBUG
import Foundation
import MieracleKit
import OSLog
import SwiftData

/// Launch arguments for driving the app in the simulator and screenshots:
/// `-localStore YES` skips iCloud (unsigned builds have no CloudKit entitlement),
/// `-seedImport <path>` imports a JSON file, `-section <name>` opens a sidebar
/// section, and `-startSession <review|practice|learnNew>` starts a session.
@MainActor
enum DebugLaunchOptions {
    /// `-selectAllOnSetup YES` pre-selects every class on the Study screen.
    nonisolated static var selectsAllOnSetup: Bool {
        UserDefaults.standard.bool(forKey: "selectAllOnSetup")
    }

    nonisolated static var usesLocalStore: Bool {
        UserDefaults.standard.bool(forKey: "localStore")
    }

    static func apply(context: ModelContext, navigation: AppNavigation) {
        let defaults = UserDefaults.standard
        if let path = defaults.string(forKey: "seedImport") {
            do {
                let document = try ImportDocument.decode(from: Data(contentsOf: URL(filePath: path)))
                try Importer(context: context).apply(document)
            } catch {
                Logger.app.error("Seed import failed: \(error)")
            }
        }
        if let name = defaults.string(forKey: "section"), let section = SidebarSection(rawValue: name) {
            navigation.selection = section
        }
        if let mode = defaults.string(forKey: "startSession").flatMap(StudyMode.init(rawValue:)) {
            navigation.startSession(SessionConfig(mode: mode))
        }
    }
}
#endif
