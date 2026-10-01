enum SidebarSection: String, CaseIterable, Identifiable {
    case dashboard
    case study
    case library
    case exams
    case settings

    var id: Self { self }

    /// Tabs on iPhone; Settings lives in the Dashboard's toolbar there.
    static let tabs: [SidebarSection] = [.dashboard, .study, .library, .exams]

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
