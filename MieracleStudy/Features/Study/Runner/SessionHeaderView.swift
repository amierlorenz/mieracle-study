import MieracleKit
import SwiftUI

struct SessionHeaderView: View {
    let engine: SessionEngine

    var body: some View {
        HStack {
            Text("\(engine.remainingCount) left")
            Spacer()
            if engine.timeRemaining() != nil {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let remaining = engine.timeRemaining(at: context.date) ?? 0
                    Text(Duration.seconds(remaining).formatted(.time(pattern: .minuteSecond)))
                        .monospacedDigit()
                        .foregroundStyle(remaining == 0 ? .red : .primary)
                }
            }
        }
        .font(.headline)
        .padding(.horizontal)
    }
}
