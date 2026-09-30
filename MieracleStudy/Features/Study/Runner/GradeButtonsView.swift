import MieracleKit
import SwiftUI

struct GradeButtonsView: View {
    let suggested: Grade?
    let onGrade: (Grade) -> Void

    var body: some View {
        HStack {
            ForEach(Array(Grade.allCases.enumerated()), id: \.element) { index, grade in
                GradeButton(grade: grade, shortcut: KeyEquivalent(Character("\(index + 1)")), isSuggested: grade == suggested) {
                    onGrade(grade)
                }
            }
        }
    }
}
