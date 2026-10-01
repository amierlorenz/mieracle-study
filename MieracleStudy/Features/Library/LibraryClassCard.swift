import MieracleKit
import SwiftUI

/// A class in the Library, styled like the Study page's class cards.
struct LibraryClassCard: View {
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.displayName)
                        .font(.title3.bold())
                        .lineLimit(2)
                    if course.displayName != course.name {
                        Text(course.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            Text("^[\(units.count) unit](inflect: true) · ^[\(conceptCount) concept](inflect: true) · ^[\(promptCount) prompt](inflect: true)")
                .font(.caption)
                .foregroundStyle(.secondary)
            if !units.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(units.prefix(6)) { unit in
                        Text(unit.name)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .glassEffect(in: .capsule)
                    }
                    if units.count > 6 {
                        Text("+\(units.count - 6) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    }
                }
            }
            if course.allowsCodingPrompts {
                Label("Programming class", systemImage: "chevron.left.forwardslash.chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect(cornerRadius: 22))
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
    }

    private var units: [CourseUnit] { course.sortedUnits }
    private var conceptCount: Int { units.reduce(0) { $0 + ($1.concepts?.count ?? 0) } }
    private var promptCount: Int { units.flatMap { $0.concepts ?? [] }.reduce(0) { $0 + ($1.prompts?.count ?? 0) } }
}
