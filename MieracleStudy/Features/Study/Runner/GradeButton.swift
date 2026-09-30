import MieracleKit
import SwiftUI

struct GradeButton: View {
    let grade: Grade
    let shortcut: KeyEquivalent
    let isSuggested: Bool
    let action: () -> Void

    var body: some View {
        if isSuggested {
            button.buttonStyle(.borderedProminent)
        } else {
            button.buttonStyle(.bordered)
        }
    }

    private var button: some View {
        Button(action: action) {
            Text(grade.title)
                .frame(maxWidth: .infinity)
        }
        .keyboardShortcut(shortcut, modifiers: [])
    }
}

extension Grade {
    var title: String {
        switch self {
        case .again: "Again"
        case .hard: "Hard"
        case .good: "Good"
        case .easy: "Easy"
        }
    }
}
