import MieracleKit
import OSLog
import SwiftData
import SwiftUI

struct CanvasSuggestionRow: View {
    let item: CanvasItem
    let courseName: String?

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                Text([courseName, item.dueAt?.formatted(date: .abbreviated, time: .shortened) ?? "No date"].compactMap { $0 }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            CopyCanvasLinkButton(item: item)
            Button("Make Exam", action: makeExam)
                .buttonStyle(.glass)
            Button("Dismiss", action: dismissItem)
                .buttonStyle(.glass)
        }
    }

    private func makeExam() {
        do {
            try CanvasSync.makeExam(from: item, in: modelContext)
        } catch {
            Logger.app.error("Making exam failed: \(error)")
        }
    }

    private func dismissItem() {
        item.isDismissed = true
        modelContext.saveLogging()
    }
}
