import SwiftUI

struct SectionDetailView: View {
    let section: SidebarSection

    var body: some View {
        switch section {
        case .dashboard: DashboardView()
        case .study: StudyView()
        case .library: LibraryView()
        case .exams: ExamsView()
        case .settings: SettingsView()
        }
    }
}
