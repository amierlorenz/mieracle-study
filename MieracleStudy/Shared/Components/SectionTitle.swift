import SwiftUI

/// A centered heading with an optional subtitle, for card-based pages.
struct SectionTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.title3.bold())
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
