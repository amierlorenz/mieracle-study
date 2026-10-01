import MieracleKit
import SwiftUI

struct FullProblemFields: View {
    @Binding var draft: PromptDraft

    var body: some View {
        Section("Problem statement") {
            TextField("Statement", text: $draft.prompt, axis: .vertical).lineLimit(4...)
        }
        OptionsSection(header: "1. Pattern options (optional, one per line)", draft: $draft)
        Section("Pattern") {
            TextField("Approach or data structure", text: $draft.answer)
        }
        Section("2. Model plan") {
            TextField("Numbered steps", text: $draft.plan, axis: .vertical).lineLimit(3...)
        }
        CodeImplementFields(draft: $draft)
        Section("4. Complexity") {
            TextField("Time, e.g. O(n log n)", text: $draft.time)
            TextField("Space, e.g. O(1)", text: $draft.space)
        }
    }
}
