import MieracleKit
import SwiftUI

/// Three glass cards for the study mode; modes with nothing to study are dimmed.
struct ModePicker: View {
    @Binding var mode: StudyMode
    let counts: [StudyMode: Int]

    var body: some View {
        VStack(spacing: 14) {
            SectionTitle(title: "How do you want to study?", subtitle: mode.explanation)
            HStack(spacing: 12) {
                ForEach(StudyMode.allCases, id: \.self) { option in
                    OptionCard(
                        title: option.title,
                        systemImage: option.systemImage,
                        detail: detail(for: option),
                        isSelected: mode == option,
                        isAvailable: (counts[option] ?? 0) > 0
                    ) {
                        mode = option
                    }
                }
            }
            .frame(maxWidth: 640)
        }
    }

    private func detail(for option: StudyMode) -> String {
        let count = counts[option] ?? 0
        return switch option {
        case .review: "\(count) due"
        case .practice: "\(count) concepts"
        case .learnNew: "\(count) new today"
        }
    }
}

extension StudyMode {
    var systemImage: String {
        switch self {
        case .review: "arrow.counterclockwise"
        case .practice: "dumbbell"
        case .learnNew: "sparkles"
        }
    }
}
