import MieracleKit
import SwiftUI

struct ConceptExplanationView: View {
    let concept: Concept

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(concept.title)
                .font(.headline)
            if !concept.explanation.isEmpty {
                RichTextView(markdown: concept.explanation)
            }
            ForEach(concept.resources, id: \.self) { resource in
                Link(resource.title, destination: resource.url)
            }
        }
    }
}
