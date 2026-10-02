import MieracleKit
import SwiftUI

/// Toolbar button that takes back the last grade, through the undo manager
/// when there is one so Cmd-Z and shake stay in step.
struct UndoAnswerButton: View {
    let engine: SessionEngine

    @Environment(\.undoManager) private var undoManager

    var body: some View {
        Button("Undo Answer", systemImage: "arrow.uturn.backward", action: undo)
            .disabled(!engine.canUndo)
            .help("Undo the last grade (Cmd-Z)")
    }

    private func undo() {
        if let undoManager, undoManager.canUndo {
            undoManager.undo()
        } else {
            withAnimation(.spring(duration: 0.4)) { engine.undoAnswer() }
        }
    }
}
