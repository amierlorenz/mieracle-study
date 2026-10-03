// PROTOTYPE — throwaway. Pieces every variant uses: claim rows, flag actions, edit sheet, approve, state readout.
import SwiftUI

struct EditTarget: Identifiable {
    let id = UUID()
    var title: String
    var text: String
    var save: (String) -> Void
}

struct EditSheet: View {
    @State var target: EditTarget
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading) {
            Text(target.title).font(.headline)
            TextEditor(text: $target.text).frame(minWidth: 480, minHeight: 140).border(.separator)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Save") { target.save(target.text); dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
}

struct DemoTag: View {
    var body: some View {
        Text("demo").font(.caption2).padding(.horizontal, 4).background(.purple.opacity(0.2), in: .capsule)
            .help("Synthetic: this didn't happen on the real deck; it's here so the interaction can be seen.")
    }
}

struct ClaimRow: View {
    var claim: Claim
    var highlighted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(claim.label).font(.caption).foregroundStyle(.secondary)
                switch claim.provenance {
                case .gapFill: Label("gap-fill, not from your material", systemImage: "puzzlepiece").font(.caption).foregroundStyle(.orange)
                case .userWritten: Label("you wrote this", systemImage: "pencil").font(.caption).foregroundStyle(.secondary)
                case .cited: EmptyView()
                }
                if claim.demo { DemoTag() }
            }
            Text(verbatim: claim.text).textSelection(.enabled)
            if let c = claim.citation {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Image(systemName: c.status == .unverified ? "exclamationmark.triangle" : "checkmark.seal")
                        .foregroundStyle(c.status == .unverified ? .orange : .secondary)
                    Text(verbatim: "Slide \(c.page)" + (c.quote.isEmpty ? "" : " · “\(c.quote)”") + " · \(c.status.rawValue)")
                        .lineLimit(2)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(highlighted ? 6 : 0)
        .background(highlighted ? Color.orange.opacity(0.12) : .clear, in: .rect(cornerRadius: 6))
    }
}

struct FlagHeader: View {
    @Environment(ReviewStore.self) private var store
    var flag: Flag

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: flag.type.symbol).foregroundStyle(.orange)
            Text(flag.type.rawValue).bold()
            if flag.demo { DemoTag() }
            if let r = store.resolutions[flag.id] {
                Label(r.rawValue, systemImage: "checkmark.circle").foregroundStyle(.green).font(.caption)
            }
        }
    }
}

struct FlagActions: View {
    @Environment(ReviewStore.self) private var store
    var flag: Flag
    @State private var editing: EditTarget?
    @State private var merging: MergeTarget?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            explanation.font(.callout).foregroundStyle(.secondary)
            if store.resolutions[flag.id] != nil {
                Button("Undo") { store.unresolve(flag) }
            } else {
                HStack { buttons }.controlSize(.small)
            }
        }
        .sheet(item: $editing) { EditSheet(target: $0) }
        .sheet(item: $merging) { MergeSheet(target: $0) }
    }

    private var cid: String { flag.candidateID ?? "" }
    private var claim: Claim? { store.candidate(cid)?.claims.first { $0.id == flag.claimID } }

    @ViewBuilder private var explanation: some View {
        switch flag.type {
        case .citationUnverified: Text("The quote wasn't found in the slide's text or OCR. Check it against the slide.")
        case .gapFill: Text("This claim isn't in your material. Keep it labelled, rewrite it, or remove it.")
        case .enrichment:
            if let e = store.candidate(cid)?.enrichment {
                Text(verbatim: "Looks like “\(e.title)” (\(e.note)). \(e.proposal)")
            }
        case .merge: Text(verbatim: "Overlaps with “\(store.title(flag.pair.last ?? ""))”.")
        case .lowConfidence: Text("The model wasn't sure this is a concept worth keeping.")
        case .missingExample: Text("Methods need a cited worked example for set-up-don't-solve practice.")
        case .missingContrast: Text(verbatim: "“\(store.title(flag.pair[0]))” and “\(store.title(flag.pair[1]))” are likely confused, but no deciding feature was found. Without one the pair still works as a distractor.")
        }
    }

    @ViewBuilder private var buttons: some View {
        switch flag.type {
        case .citationUnverified:
            Button("Quote is right") { store.confirmQuote(cid, flag.claimID!); store.resolve(flag, .confirmed) }
            Button("Edit claim…") { editClaim(resolveAs: .edited) }
            Button("Drop concept", role: .destructive) { store.drop(cid) }
        case .gapFill:
            Button("Keep, labelled") { store.resolve(flag, .kept) }
            Button("Rewrite…") { editClaim(resolveAs: nil) }
            Button("Remove claim", role: .destructive) { store.removeClaim(cid, flag.claimID!) }
        case .enrichment:
            Button("Enrich “\(store.candidate(cid)?.enrichment?.title ?? "")”") { store.resolve(flag, .enriched) }
            Button("Keep as new concept") { store.resolve(flag, .keptSeparate) }
            Button("Drop", role: .destructive) { store.drop(cid) }
        case .merge:
            Button("Compare and decide…") { merging = MergeTarget(first: flag.pair[0], second: flag.pair[1], flag: flag) }
            Button("Keep both") { store.resolve(flag, .keptSeparate) }
        case .lowConfidence:
            Button("Keep") { store.resolve(flag, .kept) }
            Button("Edit definition…") {
                if let def = store.candidate(cid)?.definition {
                    editing = EditTarget(title: "Definition", text: def.text) { store.updateClaim(cid, def.id, text: $0); store.resolve(flag, .edited) }
                }
            }
            Button("Drop", role: .destructive) { store.drop(cid) }
        case .missingExample:
            Button("Write one…") { editing = EditTarget(title: "Worked example for \(store.title(cid))", text: "") { store.addClaim(cid, label: "Worked example", text: $0) } }
            Button("Skip") { store.resolve(flag, .skipped) }
        case .missingContrast:
            Button("Write the deciding feature…") {
                if let c = store.group.contrasts.first(where: { [$0.a, $0.b] == flag.pair }) {
                    editing = EditTarget(title: "What tells \(store.title(c.a)) and \(store.title(c.b)) apart?", text: "") { store.setContrast(c.id, text: $0) }
                }
            }
            Button("Skip") { store.resolve(flag, .skipped) }
        }
    }

    private func editClaim(resolveAs resolution: Resolution?) {
        guard let claim else { return }
        editing = EditTarget(title: claim.label, text: claim.text) {
            store.updateClaim(cid, claim.id, text: $0)
            if let resolution { store.resolve(flag, resolution) }
        }
    }
}

struct CandidateMenu: View {
    @Environment(ReviewStore.self) private var store
    var id: String
    @Binding var editing: EditTarget?

    var body: some View {
        Button("Rename…") { editing = EditTarget(title: "Title", text: store.title(id)) { store.rename(id, to: $0) } }
        Picker("Kind", selection: Binding(get: { store.candidate(id)?.kind ?? .definition }, set: { store.setKind(id, $0) })) {
            ForEach(Kind.allCases, id: \.self) { Text($0.rawValue) }
        }
        Menu("Merge into") {
            ForEach(store.live.filter { $0.id != id }) { other in
                Button(other.title) { store.merge(id, into: other.id) }
            }
        }
        Divider()
        Button("Drop", role: .destructive) { store.drop(id) }
    }
}

struct MethodGroupView: View {
    @Environment(ReviewStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: store.group.name).font(.headline)
            Text(verbatim: "Question: \(store.group.question)").foregroundStyle(.secondary)
            Text(verbatim: "Members: " + store.group.members.filter { m in store.live.contains { $0.id == m } }.map(store.title).joined(separator: " · "))
            ForEach(store.group.contrasts) { contrast in
                GroupBox {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verbatim: "\(store.title(contrast.a)) ↔ \(store.title(contrast.b))").bold()
                        if let feature = contrast.decidingFeature {
                            ClaimRow(claim: feature)
                        } else if let flag = store.allFlags.first(where: { $0.type == .missingContrast && $0.pair == [contrast.a, contrast.b] }) {
                            FlagHeader(flag: flag)
                            FlagActions(flag: flag)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct ApproveButton: View {
    @Environment(ReviewStore.self) private var store
    @State private var showing = false

    var body: some View {
        let blocking = store.openFlags.filter { [.merge, .enrichment, .gapFill].contains($0.type) }.count
        Button(store.approved ? "Approved" : blocking > 0 ? "\(blocking) to decide before approving" : "Approve \(store.live.count)…") { showing = true }
            .buttonStyle(.borderedProminent)
            .disabled(store.approved || blocking > 0)
            .help("Merge candidates, matches to existing concepts and gap-fill claims must be decided first. Other flags are accepted as is.")
            .sheet(isPresented: $showing) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Approve this extraction?").font(.headline)
                    ForEach(store.summary, id: \.self) { Text("• " + $0) }
                    Text("Nothing reaches the library, sessions or iPhone until you approve.").font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Spacer()
                        Button("Keep reviewing", role: .cancel) { showing = false }
                        Button("Approve") { store.approved = true; store.record("APPROVED"); showing = false }.keyboardShortcut(.defaultAction)
                    }
                }
                .padding()
                .frame(width: 460)
            }
    }
}

struct StatePanel: View {
    @Environment(ReviewStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PROTOTYPE STATE").font(.caption.bold())
            Text("\(store.openFlags.count) open / \(store.allFlags.count) flags · \(store.live.count) live candidates").font(.caption)
            ForEach(store.summary, id: \.self) { Text("• " + $0).font(.caption2) }
            Divider()
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(Array(store.log.enumerated()), id: \.offset) { Text($0.element).font(.caption2.monospaced()) }
                }
            }
            .frame(height: 90)
        }
        .padding(8)
        .frame(width: 330)
        .background(.black.opacity(0.85), in: .rect(cornerRadius: 8))
        .foregroundStyle(.white)
    }
}

struct VariantSwitcher: View {
    @Binding var variant: Int
    static let names = ["A · Flag inbox", "B · Concept sheet", "C · Read along the deck"]
    @State private var showState = false
    @Environment(ReviewStore.self) private var store

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            HStack(spacing: 12) {
                Button { variant = (variant + 2) % 3 } label: { Image(systemName: "chevron.left") }
                    .keyboardShortcut(.leftArrow, modifiers: .option)
                Text(Self.names[variant]).bold().frame(minWidth: 190)
                Button { variant = (variant + 1) % 3 } label: { Image(systemName: "chevron.right") }
                    .keyboardShortcut(.rightArrow, modifiers: .option)
                Toggle("State · \(store.openFlags.count) open", isOn: $showState).toggleStyle(.button)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(.black.opacity(0.85), in: .capsule)
            .foregroundStyle(.white)
            .shadow(radius: 6)
            .frame(maxWidth: .infinity)
            if showState { StatePanel().padding(.bottom, 50) }
        }
        .padding(12)
    }
}
