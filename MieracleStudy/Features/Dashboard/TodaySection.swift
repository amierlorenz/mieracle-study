import SwiftUI

/// Today's numbers as glass cards, with the main actions below. Placed in the
/// section header so it sits outside the form's grouped container.
struct TodaySection: View {
    let due: Int
    let newRemaining: Int
    let reviewedToday: Int
    let onReview: () -> Void
    let onLearn: () -> Void

    var body: some View {
        Section {
        } header: {
            VStack(spacing: 18) {
                SectionTitle(title: "Today")
                HStack(spacing: 12) {
                    StatCard(value: due, title: "Due for review", systemImage: "arrow.counterclockwise", tint: due > 0 ? .orange : nil)
                    StatCard(value: newRemaining, title: "New left today", systemImage: "sparkles", tint: nil)
                    StatCard(value: reviewedToday, title: "Answered today", systemImage: "checkmark.circle", tint: reviewedToday > 0 ? .green : nil)
                }
                .frame(maxWidth: 640)
                HStack(spacing: 12) {
                    Button(action: onReview) {
                        Label("Review Due", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .lineLimit(1)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(due == 0)
                    Button(action: onLearn) {
                        Label("Learn New", systemImage: "sparkles")
                            .font(.headline)
                            .lineLimit(1)
                    }
                    .buttonStyle(.glass)
                    .disabled(newRemaining == 0)
                }
                .labelStyle(.titleAndIcon)
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .textCase(nil)
            .foregroundStyle(.primary)
        }
    }
}

private struct StatCard: View {
    let value: Int
    let title: String
    let systemImage: String
    let tint: Color?

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint ?? .secondary)
            Text("\(value)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value)))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .padding(10)
        .glassEffect(tint.map { .regular.tint($0.opacity(0.12)) } ?? .regular, in: .rect(cornerRadius: 20))
        .animation(.spring(duration: 0.4), value: value)
        .accessibilityElement(children: .combine)
    }
}
