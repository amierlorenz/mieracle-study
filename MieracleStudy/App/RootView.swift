import MieracleKit
import OSLog
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selection: SidebarSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
            }
            .navigationTitle("MieracleStudy")
        } detail: {
            SectionDetailView(section: selection ?? .dashboard)
        }
        .task(mergeDuplicates)
    }

    private func mergeDuplicates() async {
        do {
            try DuplicateMerger.mergeAll(in: modelContext)
        } catch {
            Logger.app.error("Duplicate merge failed: \(error)")
        }
    }
}

#Preview {
    RootView()
        .modelContainer(try! ModelContainerFactory.make(storage: .inMemory))
}
