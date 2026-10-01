import MieracleKit
import SwiftUI

/// Session length as a centered segmented control with a large adjustable
/// value, and order as icon cards.
struct LengthAndOrderPicker: View {
    @Binding var draft: SessionSetupDraft

    var body: some View {
        VStack(spacing: 14) {
            SectionTitle(title: "How long?")
            GlassSegmentedPicker(options: SessionSetupDraft.LengthKind.allCases, selection: $draft.lengthKind) { kind in
                switch kind {
                case .all: "Everything"
                case .count: "Items"
                case .minutes: "Minutes"
                }
            }
            .frame(maxWidth: 380)
            switch draft.lengthKind {
            case .all:
                Text("Study until every selected concept is done.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .count:
                ValueStepper(value: $draft.count, range: 5...200, step: 5, unit: "items")
            case .minutes:
                ValueStepper(value: $draft.minutes, range: 5...180, step: 5, unit: "minutes")
            }
            SectionTitle(title: "In what order?", subtitle: draft.order.explanation)
                .padding(.top, 10)
            HStack(spacing: 12) {
                ForEach(SessionConfig.Order.allCases, id: \.self) { order in
                    OptionCard(title: order.title, systemImage: order.systemImage, isSelected: draft.order == order) {
                        draft.order = order
                    }
                }
            }
            .frame(maxWidth: 640)
        }
    }
}

private struct ValueStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String

    @State private var isPicking = false

    var body: some View {
        HStack(spacing: 20) {
            Button("Less", systemImage: "minus") { change(by: -step) }
                .labelStyle(.iconOnly)
                .disabled(value <= range.lowerBound)
            Button {
                isPicking = true
            } label: {
                VStack(spacing: 0) {
                    Text("\(value)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(value)))
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 90)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Choose a value")
            .popover(isPresented: $isPicking) {
                ValuePicker(value: $value, range: range, step: step, unit: unit)
                    .presentationCompactAdaptation(.popover)
            }
            Button("More", systemImage: "plus") { change(by: step) }
                .labelStyle(.iconOnly)
                .disabled(value >= range.upperBound)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.large)
    }

    private func change(by delta: Int) {
        withAnimation(.spring(duration: 0.3)) {
            value = min(range.upperBound, max(range.lowerBound, value + delta))
        }
    }
}

/// The list of allowed values, shown when the number is tapped.
private struct ValuePicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String

    var body: some View {
        Picker(unit.capitalized, selection: $value.animation(.spring(duration: 0.3))) {
            ForEach(Array(stride(from: range.lowerBound, through: range.upperBound, by: step)), id: \.self) { option in
                Text("\(option) \(unit)").tag(option)
            }
        }
        #if os(iOS)
        .pickerStyle(.wheel)
        .frame(width: 220, height: 180)
        #else
        .pickerStyle(.inline)
        .labelsHidden()
        .frame(width: 200, height: 260)
        .padding()
        #endif
    }
}

extension SessionConfig.Order {
    var systemImage: String {
        switch self {
        case .interleaved: "shuffle"
        case .blocked: "square.stack.3d.up"
        case .hardestFirst: "flame"
        }
    }

    var explanation: String {
        switch self {
        case .interleaved: "Mixes units so you practice telling ideas apart."
        case .blocked: "Finishes one unit before the next."
        case .hardestFirst: "Starts with the concepts you miss most."
        }
    }
}
