import SwiftUI

/// A segmented choice on Liquid Glass, with the selection sliding between options.
struct GlassSegmentedPicker<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(duration: 0.35, bounce: 0.2)) { selection = option }
                } label: {
                    Text(title(option))
                        .font(.subheadline.weight(selection == option ? .semibold : .regular))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .contentShape(.capsule)
                        .background {
                            if selection == option {
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.18))
                                    .matchedGeometryEffect(id: "selection", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .foregroundStyle(selection == option ? Color.accentColor : Color.primary)
                .accessibilityAddTraits(selection == option ? .isSelected : [])
            }
        }
        .padding(4)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}
