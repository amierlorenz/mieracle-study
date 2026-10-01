import MieracleKit
import OSLog
import SwiftData
import SwiftUI

struct CanvasSuggestionRow: View {
    let item: CanvasItem

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                Text(item.dueAt?.formatted(date: .abbreviated, time: .shortened) ?? "No date")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Make Exam", action: makeExam)
            Button("Dismiss", action: dismissItem)
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
