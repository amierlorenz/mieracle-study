// PROTOTYPE — throwaway. Variant B: the whole extraction as one list of concepts, flagged first,
// flags shown as badges on the row. Selecting a concept opens an inspector with claims, flags and the slide.
// Multi-select + Merge, rename/drop from the context menu. The method group is its own section.
import SwiftUI

struct VariantB: View {
    @Environment(ReviewStore.self) private var store
    @State private var selection: Set<String> = []
    @State private var editing: EditTarget?
    @State private var showDropped = false

    var body: some View {
        let flagged = store.live.filter { !store.openFlags(for: $0.id).isEmpty }
        let clear = store.live.filter { store.openFlags(for: $0.id).isEmpty }
        List(selection: $selection) {
            Section("Needs a look (\(flagged.count))") { ForEach(flagged) { row($0) } }
            Section("Accepted (\(clear.count))") { ForEach(clear) { row($0) } }
            Section("Method group") {
                MethodGroupView().padding(.vertical, 4).selectionDisabled()
            }
            if showDropped {
                Section("Dropped or merged") {
                    ForEach(store.candidates.filter { store.dropped.contains($0.id) || store.mergedInto[$0.id] != nil }) { c in
                        HStack {
                            Text(verbatim: c.title).strikethrough()
                            Spacer()
                            Button("Restore") { store.restore(c.id) }
                        }
                        .selectionDisabled()
                    }
                }
            }
        }
        .contextMenu(forSelectionType: String.self) { ids in
            if ids.count == 1, let id = ids.first {
                CandidateMenu(id: id, editing: $editing)
            } else if ids.count > 1 {
                mergeMenu(ids)
                Button("Drop \(ids.count)", role: .destructive) { ids.forEach(store.drop) }
            }
        }
        .inspector(isPresented: .constant(true)) {
            Group {
                if selection.count == 1, let id = selection.first, let c = store.candidate(id) {
                    Inspector(candidate: c)
                } else if selection.count > 1 {
                    VStack(alignment: .leading) {
                        Text("\(selection.count) selected").font(.headline)
                        mergeMenu(selection)
                    }
                    .padding()
                } else {
                    ContentUnavailableView("Select a concept", systemImage: "sidebar.right")
                }
            }
            .inspectorColumnWidth(min: 360, ideal: 460, max: 700)
        }
        .toolbar {
            ToolbarItem { Toggle("Show dropped", isOn: $showDropped) }
            ToolbarItem { ApproveButton() }
        }
        .sheet(item: $editing) { EditSheet(target: $0) }
    }

    private func mergeMenu(_ ids: Set<String>) -> some View {
        Menu("Merge \(ids.count) into…") {
            ForEach(Array(ids), id: \.self) { target in
                Button(store.title(target)) { ids.filter { $0 != target }.forEach { store.merge($0, into: target) } }
            }
        }
        .fixedSize()
    }

    private func row(_ c: Candidate) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(verbatim: c.title).bold()
                Text(c.kind.rawValue).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("slide \(c.page)").font(.caption).foregroundStyle(.secondary)
            }
            Text(verbatim: c.definition?.text ?? "").lineLimit(2).foregroundStyle(.secondary)
            let flags = store.openFlags(for: c.id)
            if !flags.isEmpty {
                HStack {
                    ForEach(flags) { f in
                        Label(f.type.rawValue, systemImage: f.type.symbol).font(.caption).foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 3)
        .tag(c.id)
    }
}

private struct Inspector: View {
    @Environment(ReviewStore.self) private var store
    var candidate: Candidate
    @State private var editing: EditTarget?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(verbatim: candidate.title).font(.title3.bold())
                    Spacer()
                    Menu("Concept") { CandidateMenu(id: candidate.id, editing: $editing) }.fixedSize()
                }
                ForEach(store.flags(for: candidate.id)) { flag in
                    GroupBox {
                        VStack(alignment: .leading, spacing: 6) {
                            FlagHeader(flag: flag)
                            FlagActions(flag: flag)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                ForEach(candidate.claims) { claim in
                    ClaimRow(claim: claim, highlighted: store.openFlags(for: candidate.id).contains { $0.claimID == claim.id })
                        .contextMenu {
                            Button("Edit…") { editing = EditTarget(title: claim.label, text: claim.text) { store.updateClaim(candidate.id, claim.id, text: $0) } }
                            Button("Remove", role: .destructive) { store.removeClaim(candidate.id, claim.id) }
                        }
                }
                Button("Add a cue…") { editing = EditTarget(title: "Use when", text: "") { store.addClaim(candidate.id, label: "Use when", text: $0) } }
                Divider()
                SlideView(page: candidate.page, quotes: candidate.claims.compactMap { $0.citation?.page == candidate.page ? $0.citation?.quote : nil })
            }
            .padding()
            .padding(.bottom, 160)
        }
        .sheet(item: $editing) { EditSheet(target: $0) }
    }
}
