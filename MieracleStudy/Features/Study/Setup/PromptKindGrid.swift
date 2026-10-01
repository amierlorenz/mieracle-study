import MieracleKit
import SwiftUI

/// Prompt types as selectable cards; only types present in the selection appear.
struct PromptKindGrid: View {
    @Binding var kinds: Set<PromptKind>
    /// Prompt counts per kind within the selected scope.
    let counts: [PromptKind: Int]

    var body: some View {
        VStack(spacing: 14) {
            SectionTitle(title: "Which kinds of prompts?")
            if available.isEmpty {
                Text("Select classes above to see their prompt types.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(available) { kind in
                        OptionCard(
                            title: kind.displayName,
                            systemImage: kind.systemImage,
                            detail: "\(counts[kind] ?? 0) prompts",
                            isSelected: kinds.contains(kind)
                        ) {
                            toggle(kind)
                        }
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.4), value: available)
            }
        }
    }

    private var available: [PromptKind] {
        PromptKind.allCases.filter { (counts[$0] ?? 0) > 0 }
    }

    private func toggle(_ kind: PromptKind) {
        if kinds.contains(kind) {
            kinds.remove(kind)
        } else {
            kinds.insert(kind)
        }
    }
}

extension PromptKind {
    var systemImage: String {
        switch self {
        case .flashcard: "rectangle.on.rectangle.angled"
        case .shortAnswer: "text.bubble"
        case .multipleChoice: "list.bullet.circle"
        case .codeImplement: "chevron.left.forwardslash.chevron.right"
        case .codeComplexity: "gauge.with.dots.needle.67percent"
        case .patternPick: "puzzlepiece"
        case .fullProblem: "square.stack.3d.forward.dottedline"
        }
    }
}
