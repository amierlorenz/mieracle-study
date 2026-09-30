import MieracleKit
import SwiftUI

struct ImportCountsRow: View {
    let title: String
    let counts: ImportPlan.Counts

    var body: some View {
        LabeledContent(title, value: "\(counts.new) new · \(counts.updated) updated · \(counts.unchanged) unchanged")
    }
}
