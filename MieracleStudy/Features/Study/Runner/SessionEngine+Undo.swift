import Foundation
import MieracleKit
import OSLog

extension SessionEngine {
    /// Registers the latest answer with the system undo manager, which gives
    /// Cmd-Z (Edit menu) on the Mac and shake-to-undo on iPhone.
    func registerAnswerUndo(with undoManager: UndoManager?) {
        guard let undoManager else { return }
        undoManager.registerUndo(withTarget: self) { engine in
            MainActor.assumeIsolated { engine.undoAnswer() }
        }
        undoManager.setActionName("Answer")
    }

    /// Takes back the latest answer, logging instead of throwing.
    func undoAnswer() {
        guard canUndo else { return }
        do {
            try undoLastAnswer()
        } catch {
            Logger.app.error("Undoing answer failed: \(error)")
        }
    }
}
