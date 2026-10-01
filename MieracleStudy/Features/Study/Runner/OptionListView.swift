import SwiftUI

/// Answer choices. Once revealed, the learner's pick and the correct answer
/// stay prominent, the rest fade, and each choice can explain itself.
struct OptionListView: View {
    let options: [String]
    /// The correct index once revealed; `nil` while answering.
    let correct: Int?
    @Binding var selection: Int?
    /// Asks for an explanation of the choice at an index; `nil` hides the buttons.
    var explain: ((Int) async -> String?)?

    @State private var explanations: [Int: String] = [:]
    @State private var loading: Set<Int> = []

    var body: some View {
        ForEach(options.indices, id: \.self) { index in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
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
                    if correct != nil, explain != nil, explanations[index] == nil {
                        Button("Why?") { Task { await loadExplanation(for: index) } }
                            .buttonStyle(.glass)
                            .controlSize(.mini)
                            .disabled(loading.contains(index))
                    }
                }
                if loading.contains(index) {
                    ProgressView()
                        .controlSize(.small)
                } else if let explanation = explanations[index] {
                    Text(explanation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 28)
                }
            }
            .opacity(isFaded(index) ? 0.35 : 1)
        }
    }

    private func isFaded(_ index: Int) -> Bool {
        guard let correct else { return false }
        return index != correct && index != selection && explanations[index] == nil
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
        return .primary
    }

    private func loadExplanation(for index: Int) async {
        guard let explain else { return }
        loading.insert(index)
        defer { loading.remove(index) }
        explanations[index] = await explain(index) ?? "Couldn't get an explanation right now."
    }
}
