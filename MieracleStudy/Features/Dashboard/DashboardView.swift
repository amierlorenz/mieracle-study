import SwiftUI

struct DashboardView: View {
    var body: some View {
        ContentUnavailableView("Dashboard", systemImage: "hammer", description: Text("Coming soon."))
            .navigationTitle("Dashboard")
    }
}
