enum SidebarSection: String, CaseIterable, Identifiable {
    case dashboard
    case study
    case library
    case exams
    case importExport
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .study: "Study"
        case .library: "Library"
        case .exams: "Exams"
        case .importExport: "Import"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.33percent"
        case .study: "brain.head.profile"
        case .library: "books.vertical"
        case .exams: "calendar"
        case .importExport: "square.and.arrow.down"
        case .settings: "gearshape"
        }
    }
}
