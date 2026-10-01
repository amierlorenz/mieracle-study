import SwiftUI

/// The due date in a capsule colored by urgency.
struct DueDateBadge: View {
    let date: Date

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                .font(.subheadline.weight(.semibold))
            Text(date.formatted(.relative(presentation: .named)))
                .font(.caption2)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tint.opacity(0.15), in: .capsule)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Due \(date.formatted(date: .complete, time: .shortened))")
    }

    private var tint: Color {
        let hours = date.timeIntervalSinceNow / 3600
        if hours < 48 { return .red }
        if hours < 7 * 24 { return .orange }
        return .blue
    }
}
