import SwiftUI

struct OptionListView: View {
    let options: [String]
    /// The correct index once revealed; `nil` while answering.
    let correct: Int?
    @Binding var selection: Int?

    var body: some View {
        ForEach(options.indices, id: \.self) { index in
            Button {
                selection = index
            } label: {
                Label(options[index], systemImage: symbol(for: index))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(color(for: index))
            .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
        }
    }

    private func symbol(for index: Int) -> String {
        if let correct {
            if index == correct { return "checkmark.circle.fill" }
            if index == selection { return "xmark.circle.fill" }
        }
        return index == selection ? "largecircle.fill.circle" : "circle"
    }

    private func color(for index: Int) -> Color {
        guard let correct else { return .primary }
        if index == correct { return .green }
        if index == selection { return .red }
        return .secondary
    }
}
