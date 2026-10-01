import MieracleKit
import SwiftData
import SwiftUI

/// What changed in Canvas since you last looked: new, removed, and moved items.
struct CanvasChangesCard: View {
    @Environment(CanvasService.self) private var canvas
    @Query private var courses: [Course]

    var body: some View {
        if !canvas.pendingChanges.isEmpty {
            Section {
                ForEach(canvas.pendingChanges) { change in
                    CanvasChangeRow(change: change, courseName: courseName(for: change))
                        .swipeActions {
                            Button("Dismiss", systemImage: "xmark") { withAnimation(.spring(duration: 0.35)) { canvas.dismiss(change) } }
                        }
                        .contextMenu {
                            Button("Dismiss", systemImage: "xmark") { withAnimation(.spring(duration: 0.35)) { canvas.dismiss(change) } }
                        }
                }
                Button("Got It", systemImage: "checkmark") {
                    withAnimation(.spring(duration: 0.4)) { canvas.dismissChanges() }
                }
                .buttonStyle(.glass)
                .frame(maxWidth: .infinity)
            } header: {
                Label("Changes in Canvas", systemImage: "arrow.triangle.2.circlepath")
            } footer: {
                Text("Found by the latest syncs. Exam dates already follow Canvas.")
            }
        }
    }

    private func courseName(for change: CanvasChange) -> String? {
        courses.first { $0.canvasCourseID == change.canvasCourseID }?.displayName
    }
}

private struct CanvasChangeRow: View {
    let change: CanvasChange
    let courseName: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .font(.title3)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(change.name)
                        .fontWeight(change.isExam ? .semibold : .regular)
                    if change.isExam {
                        Text("Exam")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2), in: .capsule)
                    }
                }
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var symbol: String {
        switch change.kind {
        case .added: "plus.circle.fill"
        case .removed: "minus.circle.fill"
        case .rescheduled: "calendar.badge.clock"
        }
    }

    private var tint: Color {
        switch change.kind {
        case .added: .green
        case .removed: .red
        case .rescheduled: .orange
        }
    }

    private var detail: String {
        let format: (Date?) -> String = { $0?.formatted(date: .abbreviated, time: .shortened) ?? "no date" }
        let prefix = courseName.map { "\($0) · " } ?? ""
        return switch change.kind {
        case .added: "\(prefix)New, due \(format(change.newDate))"
        case .removed: "\(prefix)Removed from Canvas (was due \(format(change.oldDate)))"
        case .rescheduled: "\(prefix)\(format(change.oldDate)) → \(format(change.newDate))"
        }
    }
}
