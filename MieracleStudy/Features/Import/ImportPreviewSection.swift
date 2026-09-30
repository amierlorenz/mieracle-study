import MieracleKit
import SwiftUI

struct ImportPreviewSection: View {
    let pending: PendingImport
    let onApply: () -> Void
    let onCancel: () -> Void

    var body: some View {
        Section("Preview: \(pending.source)") {
            ImportCountsRow(title: "Classes", counts: pending.plan.courses)
            ImportCountsRow(title: "Units", counts: pending.plan.units)
            ImportCountsRow(title: "Concepts", counts: pending.plan.concepts)
            ImportCountsRow(title: "Prompts", counts: pending.plan.prompts)
            ImportCountsRow(title: "Exams", counts: pending.plan.exams)
            HStack {
                Button("Cancel", role: .cancel, action: onCancel)
                Spacer()
                Button("Import", action: onApply)
                    .buttonStyle(.borderedProminent)
                    .disabled(!pending.plan.canApply || !pending.plan.hasChanges)
            }
        }
        if !pending.plan.issues.isEmpty {
            Section("Issues") {
                ForEach(pending.plan.issues, id: \.self) { issue in
                    Label {
                        VStack(alignment: .leading) {
                            Text(issue.message)
                            Text(issue.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: issue.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(issue.severity == .error ? .red : .orange)
                    }
                }
            }
        }
    }
}
