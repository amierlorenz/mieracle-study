import MieracleKit
import SwiftUI

struct AssignmentRow: View {
    let item: CanvasItem
    let courseName: String?
    let onComplete: (CanvasItem) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button("Mark Done", systemImage: "circle", action: markDone)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            CopyCanvasLinkButton(item: item)
            if let due = item.dueAt {
                DueDateBadge(date: due)
            }
        }
    }

    private var subtitle: String? {
        var parts: [String] = []
        if let courseName { parts.append(courseName) }
        if let unlock = item.unlockAt, unlock > .now { parts.append("opens \(unlock.formatted(date: .abbreviated, time: .omitted))") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func markDone() {
        onComplete(item)
    }
}
