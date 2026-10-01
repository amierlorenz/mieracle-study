import MieracleKit
import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(AppNavigation.self) private var navigation
    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.dailyNewLimit) private var dailyNewLimit = NewConceptBudget.defaultLimit
    @Query(sort: \Course.name) private var courses: [Course]
    @Query(sort: \Exam.date) private var exams: [Exam]
    @Query private var reviews: [ReviewLog]

    var body: some View {
        let overview = StudyOverview(courses: courses, exams: exams)
        NavigationStack {
            Form {
                TodaySection(
                    due: overview.courses.reduce(0) { $0 + $1.due },
                    newRemaining: newRemaining,
                    reviewedToday: reviewedToday,
                    onReview: { navigation.startSession(SessionConfig(mode: .review)) },
                    onLearn: { navigation.startSession(SessionConfig(mode: .learnNew)) }
                )
                AssignmentsSection()
                if !overview.exams.isEmpty {
                    Section("Upcoming exams") {
                        ForEach(overview.exams) { exam in
                            ExamReadinessRow(exam: exam) { prepare(for: exam) }
                        }
                    }
                }
                Section("Classes") {
                    ForEach(overview.courses) { course in
                        CourseCountsRow(course: course) {
                            navigation.startSession(SessionConfig(scope: .init(courseIDs: [course.id]), mode: .review))
                        }
                    }
                    if overview.courses.isEmpty {
                        Text("Import or add a class to get started.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Dashboard")
            .inlineTitleOnPhone()
        }
    }

    private var reviewedToday: Int {
        let start = Calendar.current.startOfDay(for: .now)
        return reviews.count { $0.reviewedAt >= start }
    }

    private var newRemaining: Int {
        (try? NewConceptBudget.remaining(limit: dailyNewLimit, in: modelContext)) ?? dailyNewLimit
    }

    private func prepare(for exam: StudyOverview.ExamReadiness) {
        navigation.startSession(SessionConfig(scope: exam.scope, mode: .practice, length: .minutes(25), order: .hardestFirst))
    }
}
