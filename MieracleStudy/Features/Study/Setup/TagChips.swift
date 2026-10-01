import MieracleKit
import SwiftUI

/// Tags as toggleable chips; a tag adds every concept carrying it.
struct TagChips: View {
    let tags: [ConceptTag]
    @Binding var selection: Set<String>

    var body: some View {
        VStack(spacing: 12) {
            SectionTitle(title: "Tags", subtitle: "Add concepts by tag, across classes.")
            FlowLayout {
                ForEach(tags) { tag in
                    SelectableChip(title: tag.name, state: selection.contains(tag.name) ? .all : .none) {
                        if selection.contains(tag.name) {
                            selection.remove(tag.name)
                        } else {
                            selection.insert(tag.name)
                        }
                    }
                }
            }
        }
    }
}
