// PROTOTYPE — throwaway. Side-by-side merge decision: pick which candidate survives.
import SwiftUI

struct MergeTarget: Identifiable {
    let id = UUID()
    var first: String
    var second: String?
    var flag: Flag?
}

struct MergeSheet: View {
    @Environment(ReviewStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var target: MergeTarget
    @State private var other: String = ""
    @State private var keep: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(target.flag == nil ? "Merge two concepts" : "These look like the same concept").font(.title3.bold())
            if target.second == nil {
                Picker("Merge with", selection: $other) {
                    ForEach(store.live.filter { $0.id != target.first }) { Text(verbatim: $0.title).tag($0.id) }
                }
                .fixedSize()
            }
            HStack(alignment: .top, spacing: 12) {
                column(target.first)
                if !other.isEmpty { column(other) }
            }
            Text("The one you keep keeps its title, kind and definition. The other's definition becomes an extra claim, and its cues and worked examples move over with their citations.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                if let flag = target.flag {
                    Button("Keep both") { store.resolve(flag, .keptSeparate); dismiss() }
                }
                Button("Merge into “\(store.title(keep))”") {
                    store.merge(keep == target.first ? other : target.first, into: keep)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(other.isEmpty || keep.isEmpty)
            }
        }
        .padding()
        .frame(width: 900)
        .onAppear {
            let first = store.candidate(target.first)
            other = target.second ?? first?.mergeWith
                ?? store.live.first { $0.id != target.first && $0.page == first?.page }?.id
                ?? store.live.first { $0.id != target.first }?.id ?? ""
            keep = target.first
        }
    }

    private func column(_ id: String) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    keep = id
                } label: {
                    Label(keep == id ? "Keeping this one" : "Keep this one", systemImage: keep == id ? "checkmark.circle.fill" : "circle")
                }
                if let c = store.candidate(id) {
                    Text(verbatim: c.title).font(.headline)
                    Text("\(c.kind.rawValue) · slide \(c.page) · \(c.claims.count) claims").font(.caption).foregroundStyle(.secondary)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(c.claims) { ClaimRow(claim: $0) }
                        }
                    }
                    .frame(height: 300)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(keep == id ? 1 : 0.6)
        }
    }
}
