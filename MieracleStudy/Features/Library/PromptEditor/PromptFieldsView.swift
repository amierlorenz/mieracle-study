import MieracleKit
import SwiftUI

struct PromptFieldsView: View {
    @Binding var draft: PromptDraft

    var body: some View {
        switch draft.kind {
        case .flashcard: FlashcardFields(draft: $draft)
        case .shortAnswer: ShortAnswerFields(draft: $draft)
        case .multipleChoice: MultipleChoiceFields(draft: $draft)
        case .codeImplement: CodeImplementFields(draft: $draft)
        case .codeComplexity: CodeComplexityFields(draft: $draft)
        case .patternPick: PatternPickFields(draft: $draft)
        case .fullProblem: FullProblemFields(draft: $draft)
        }
    }
}
