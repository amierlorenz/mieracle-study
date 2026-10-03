// PROTOTYPE — throwaway. Variant A: a triage inbox. Only flags are listed; one flag at a time,
// with the candidate's claims and the cited slide side by side. Unflagged candidates are a count.
import SwiftUI

struct VariantA: View {
    @Environment(ReviewStore.self) private var store
    @State private var selection: String?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(FlagType.allCases, id: \.self) { type in
                    let flags = store.allFlags.filter { $0.type == type }
                    if !flags.isEmpty {
                        Section("\(type.rawValue) (\(flags.filter { store.resolutions[$0.id] == nil }.count))") {
                            ForEach(flags) { flag in
                                HStack {
                                    Image(systemName: store.resolutions[flag.id] == nil ? flag.type.symbol : "checkmark.circle")
                                        .foregroundStyle(store.resolutions[flag.id] == nil ? .orange : .green)
                                    Text(verbatim: flag.candidateID.map(store.title) ?? flag.pair.map(store.title).joined(separator: " ↔ "))
                                        .lineLimit(2)
                                    if flag.demo { DemoTag() }
                                }
                                .tag(flag.id)
                            }
                        }
                    }
                }
                Section("Accepted, nothing to check (\(store.unflagged.count))") {
                    DisclosureGroup("Show") {
                        ForEach(store.unflagged) { Text(verbatim: $0.title).foregroundStyle(.secondary) }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 320)
        } detail: {
            if let flag = store.allFlags.first(where: { $0.id == selection }) {
                FlagDetail(flag: flag, next: nextFlag)
            } else {
                ContentUnavailableView("\(store.openFlags.count) flags to check",
                                       systemImage: "flag",
                                       description: Text("\(store.live.count) candidates from \(store.deckName). Everything else is accepted."))
            }
        }
        .toolbar {
            ToolbarItem { Button("Next flag", systemImage: "arrow.down.circle", action: nextFlag).keyboardShortcut("j", modifiers: []) }
            ToolbarItem { ApproveButton() }
        }
        .onAppear { if selection == nil { selection = store.openFlags.first?.id } }
    }

    private func nextFlag() {
        let open = store.openFlags
        let i = open.firstIndex { $0.id == selection } ?? -1
        selection = open.isEmpty ? nil : open[(i + 1) % open.count].id
    }
}

private struct FlagDetail: View {
    @Environment(ReviewStore.self) private var store
    var flag: Flag
    var next: () -> Void
    @State private var editing: EditTarget?

    var body: some View {
        HSplitView {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    FlagHeader(flag: flag)
                    FlagActions(flag: flag)
                    if store.resolutions[flag.id] != nil { Button("Next flag", action: next) }
                    Divider()
                    ForEach(flag.candidateID.map { [$0] } ?? flag.pair, id: \.self) { id in
                        if let c = store.candidate(id) {
                            HStack {
                                Text(verbatim: c.title).font(.title3.bold())
                                Text(c.kind.rawValue).foregroundStyle(.secondary)
                                Spacer()
                                Menu("Concept") { CandidateMenu(id: id, editing: $editing) }.fixedSize()
                            }
                            ForEach(c.claims) { claim in
                                ClaimRow(claim: claim, highlighted: claim.id == flag.claimID)
                            }
                        }
                    }
                    if flag.type == .merge, let other = flag.pair.last.flatMap(store.candidate) {
                        Divider()
                        Text(verbatim: "Other candidate: \(other.title)").font(.title3.bold())
                        ForEach(other.claims) { ClaimRow(claim: $0) }
                    }
                }
                .padding()
                .padding(.bottom, 160)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minWidth: 380)
            ScrollView {
                SlideView(page: store.page(of: flag), quotes: [store.quote(of: flag) ?? ""]).padding()
            }
            .frame(minWidth: 360)
        }
        .sheet(item: $editing) { EditSheet(target: $0) }
    }
}
