import SwiftUI

struct ExamsView: View {
    var body: some View {
        ContentUnavailableView("Exams", systemImage: "hammer", description: Text("Coming soon."))
            .navigationTitle("Exams")
    }
}
