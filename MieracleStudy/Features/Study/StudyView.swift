import SwiftUI

struct StudyView: View {
    var body: some View {
        ContentUnavailableView("Study", systemImage: "hammer", description: Text("Coming soon."))
            .navigationTitle("Study")
    }
}
