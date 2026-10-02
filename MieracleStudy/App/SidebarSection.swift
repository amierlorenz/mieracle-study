enum SidebarSection: String, CaseIterable, Identifiable {
    case dashboard
    case study
    case library
    case exams
    case settings

    var id: Self { self }

    /// The app's tabs. On iPhone, Settings opens from the Home toolbar instead.
    static var tabs: [SidebarSection] {
        #if os(iOS)
        [.dashboard, .study, .library, .exams]
        #else
        allCases
        #endif
    }

    var title: String {
        switch self {
        case .dashboard: "Home"
        case .study: "Study"
        case .library: "Library"
        case .exams: "Exams"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "house"
        case .study: "brain.head.profile"
        case .library: "books.vertical"
        case .exams: "calendar"
        case .settings: "gearshape"
        }
    }
}
