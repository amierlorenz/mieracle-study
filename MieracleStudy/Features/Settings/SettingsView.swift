import SwiftUI

struct SettingsView: View {
    var body: some View {
        ContentUnavailableView("Settings", systemImage: "hammer", description: Text("Coming soon."))
            .navigationTitle("Settings")
    }
}
