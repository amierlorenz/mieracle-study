import MieracleKit
import SwiftData
import SwiftUI

/// Canvas sync controls and exam suggestions from Canvas items.
struct CanvasExamsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CanvasService.self) private var canvas
    @Query(sort: \CanvasItem.dueAt) private var items: [CanvasItem]
    @State private var isLinking = false

    var body: some View {
        if canvas.client() == nil {
            Section("Canvas") {
                Text("Add your Canvas URL and token in Settings to pull exam dates automatically.")
                    .foregroundStyle(.secondary)
            }
        } else {
            Section {
                HStack {
                    Button(canvas.isSyncing ? "Syncing…" : "Sync Now", systemImage: "arrow.triangle.2.circlepath") {
                        Task { await canvas.sync(context: modelContext) }
                    }
                    .disabled(canvas.isSyncing)
                    Spacer()
                    Button("Link Classes…", systemImage: "link") { isLinking = true }
                }
                if let lastSync = canvas.lastSync {
                    Text("Last synced \(lastSync.formatted(.relative(presentation: .named)))")
                        .foregroundStyle(.secondary)
                }
                if let error = canvas.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Canvas")
            }
            .sheet(isPresented: $isLinking) {
                CanvasLinkSheet()
            }
            if !suggestions.isEmpty {
                Section {
                    ForEach(suggestions) { item in
                        CanvasSuggestionRow(item: item)
                    }
                } header: {
                    Text("Suggested from Canvas")
                } footer: {
                    Text("Upcoming items whose names look like exams. Make one an exam, then choose its units.")
                }
            }
        }
    }

    private var suggestions: [CanvasItem] {
        items.filter { $0.looksLikeExam && !$0.isExam && !$0.isDismissed && ($0.dueAt ?? .distantFuture) >= .now }
    }
}
