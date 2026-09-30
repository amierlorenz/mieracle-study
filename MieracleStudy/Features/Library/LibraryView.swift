import SwiftUI

struct LibraryView: View {
    var body: some View {
        ContentUnavailableView("Library", systemImage: "hammer", description: Text("Coming soon."))
            .navigationTitle("Library")
    }
}
