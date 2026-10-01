import MieracleKit
import SwiftData
import SwiftUI

struct ExamsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CanvasService.self) private var canvas
    @Query(sort: \Exam.date) private var exams: [Exam]
    @State private var isAdding = false
    @State private var path: [Exam] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                CanvasExamsSection()
                Section("Upcoming") {
                    ForEach(upcoming) { exam in
                        NavigationLink(value: exam) { ExamRow(exam: exam) }
                    }
                    if upcoming.isEmpty {
                        Text("No upcoming exams.")
                            .foregroundStyle(.secondary)
                    }
                }
                if !past.isEmpty {
                    Section("Past") {
                        ForEach(past.reversed()) { exam in
                            NavigationLink(value: exam) { ExamRow(exam: exam) }
                        }
                    }
                }
            }
            .navigationTitle("Exams")
            .navigationDestination(for: Exam.self, destination: ExamDetailView.init)
            .toolbar {
                Button("Add Exam", systemImage: "plus") { isAdding = true }
            }
            .sheet(isPresented: $isAdding) {
                NewExamSheet { path.append($0) }
            }
        }
    }

    private var startOfToday: Date { Calendar.current.startOfDay(for: .now) }
    private var upcoming: [Exam] { exams.filter { $0.date >= startOfToday } }
    private var past: [Exam] { exams.filter { $0.date < startOfToday } }
}
