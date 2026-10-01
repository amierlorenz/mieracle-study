import MieracleKit
import OSLog
import SwiftData
import SwiftUI

struct DataSettingsSection: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isConfirming = false
    @State private var status: String?

    var body: some View {
        Section {
            Button("Delete All Data", systemImage: "trash", role: .destructive) { isConfirming = true }
                .foregroundStyle(.red)
                .confirmationDialog("Delete all study data?", isPresented: $isConfirming, titleVisibility: .visible) {
                    Button("Delete Everything", role: .destructive, action: deleteAll)
                } message: {
                    Text("Removes every class, concept, prompt, exam, review, and preset on all your devices through iCloud. Export a backup from Import first if you might want it back. This can't be undone.")
                }
            if let status {
                Text(status)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Data")
        } footer: {
            Text("Settings and your Canvas token are kept.")
        }
    }

    private func deleteAll() {
        do {
            try DataReset.deleteAll(in: modelContext)
            UserDefaults.standard.removeObject(forKey: SettingsKey.canvasLastSync)
            status = "All study data deleted."
        } catch {
            Logger.app.error("Delete all failed: \(error)")
            status = "Couldn't delete everything: \(error.localizedDescription)"
        }
    }
}
