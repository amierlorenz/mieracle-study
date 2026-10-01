import MieracleKit
import SwiftData
import SwiftUI

struct AssignmentRow: View {
    let item: CanvasItem
    let courseName: String?

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Done", systemImage: "checkmark.circle", action: markDone)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
        }
    }

    private var details: String {
        var parts: [String] = []
        if let courseName { parts.append(courseName) }
        if let due = item.dueAt { parts.append("due \(due.formatted(.relative(presentation: .named)))") }
        if let unlock = item.unlockAt, unlock > .now { parts.append("opens \(unlock.formatted(date: .abbreviated, time: .omitted))") }
        return parts.joined(separator: " · ")
    }

    private func markDone() {
        item.isMarkedDone = true
        modelContext.saveLogging()
    }
}
