import MieracleKit
import SwiftUI

struct ExplanationSection: View {
    let concept: Concept

    @State private var isExpanded: Bool

    init(concept: Concept, startsExpanded: Bool) {
        self.concept = concept
        _isExpanded = State(initialValue: startsExpanded)
    }

    var body: some View {
        Section {
            DisclosureGroup("Explanation", isExpanded: $isExpanded) {
                ConceptExplanationView(concept: concept)
            }
        }
    }
}
