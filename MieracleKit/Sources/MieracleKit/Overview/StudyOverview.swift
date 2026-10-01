import Foundation

/// Counts for the dashboard: what's due per class and how ready each upcoming exam is.
public struct StudyOverview: Equatable, Sendable {
    public struct CourseCounts: Equatable, Sendable, Identifiable {
        public var id: String
        public var name: String
        public var due: Int
        public var new: Int
        public var total: Int
    }

    public struct ExamReadiness: Equatable, Sendable, Identifiable {
        public var id: String
        public var name: String
        public var courseName: String
        public var date: Date
        public var daysLeft: Int
        public var conceptCount: Int
        /// Concepts studied at least once.
        public var studied: Int
        /// Studied concepts that keep slipping: low ease or repeated lapses.
        public var weak: Int
        public var scope: SessionConfig.Scope

        public var studiedFraction: Double {
            conceptCount == 0 ? 0 : Double(studied) / Double(conceptCount)
        }
    }

    public var courses: [CourseCounts]
    public var exams: [ExamReadiness]

    /// A concept is weak once it's been studied and its ease fell below this or it lapsed twice.
    public static let weakEase = 2.1
    public static let weakLapses = 2

    @MainActor
    public init(courses: [Course], exams: [Exam], now: Date = .now, calendar: Calendar = .current) {
        self.courses = courses.map { course in
            let concepts = course.sortedUnits.flatMap { $0.concepts ?? [] }
            return CourseCounts(
                id: course.externalID,
                name: course.name,
                due: concepts.count { $0.isDue(at: now) },
                new: concepts.count(where: \.isNew),
                total: concepts.count
            )
        }
        let today = calendar.startOfDay(for: now)
        self.exams = exams
            .filter { $0.date >= today }
            .sorted { $0.date < $1.date }
            .map { exam in
                let concepts = (exam.course?.sortedUnits ?? []).flatMap { $0.concepts ?? [] }.filter(exam.covers)
                let studied = concepts.filter { !$0.isNew }
                return ExamReadiness(
                    id: exam.externalID,
                    name: exam.name,
                    courseName: exam.course?.name ?? "",
                    date: exam.date,
                    daysLeft: calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: exam.date)).day ?? 0,
                    conceptCount: concepts.count,
                    studied: studied.count,
                    weak: studied.count { $0.ease < Self.weakEase || $0.lapses >= Self.weakLapses },
                    scope: SessionConfig.Scope(unitIDs: Set((exam.units ?? []).map(\.externalID)), tags: Set((exam.tags ?? []).map(\.name)))
                )
            }
    }
}
