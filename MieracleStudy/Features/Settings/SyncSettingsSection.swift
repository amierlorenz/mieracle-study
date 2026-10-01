import CloudKit
import SwiftUI

struct SyncSettingsSection: View {
    @Environment(SyncStatusService.self) private var sync

    var body: some View {
        Section {
            LabeledContent("iCloud account", value: accountText)
            LabeledContent("Status", value: sync.isSyncing ? "Syncing…" : "Idle")
            EventRow(title: "Last download", event: sync.lastImport)
            EventRow(title: "Last upload", event: sync.lastExport)
        } header: {
            Text("iCloud Sync")
        } footer: {
            Text("Classes, concepts, and reviews sync through your private iCloud database. Times reset when the app relaunches.")
        }
        .task { await sync.refreshAccountStatus() }
    }

    private var accountText: String {
        switch sync.accountStatus {
        case .available: "Signed in"
        case .noAccount: "Not signed in"
        case .restricted: "Restricted"
        case .temporarilyUnavailable: "Temporarily unavailable"
        case .couldNotDetermine, .none: "Checking…"
        @unknown default: "Unknown"
        }
    }
}

private struct EventRow: View {
    let title: String
    let event: SyncStatusService.EventSummary?

    var body: some View {
        if let event {
            VStack(alignment: .leading, spacing: 2) {
                LabeledContent(title) {
                    Label(
                        event.finishedAt?.formatted(.relative(presentation: .named)) ?? "—",
                        systemImage: event.succeeded ? "checkmark.icloud" : "exclamationmark.icloud"
                    )
                    .foregroundStyle(event.succeeded ? Color.secondary : Color.red)
                }
                if let message = event.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        } else {
            LabeledContent(title, value: "Not yet this launch")
        }
    }
}
