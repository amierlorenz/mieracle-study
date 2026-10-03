// PROTOTYPE — throwaway. Variant C: read along the deck. One slide at a time, large, with every quote
// on it highlighted; the concepts cited on that slide sit beside it with their flags inline. A strip of
// slide numbers shows where flags are. After the last slide: the method group, then Approve.
import SwiftUI

struct VariantC: View {
    @Environment(ReviewStore.self) private var store
    @State private var step = 1
    @State private var editing: EditTarget?

    private var pages: Int { max(SlideCache.shared.pageCount, store.candidates.map(\.page).max() ?? 1) }
    private var groupStep: Int { pages + 1 }

    var body: some View {
        VStack(spacing: 0) {
            strip
            Divider()
            if step == groupStep {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Which method applies").font(.title2.bold())
                        Text("Methods that compete for the same question, and what tells each pair apart.").foregroundStyle(.secondary)
                        MethodGroupView()
                        HStack { Spacer(); ApproveButton() }
                    }
                    .padding()
                    .padding(.bottom, 160)
                    .frame(maxWidth: 760, alignment: .leading)
                }
            } else {
                HSplitView {
                    ScrollView {
                        SlideView(page: step, quotes: onPage.flatMap { $0.claims.compactMap { $0.citation?.page == step ? $0.citation?.quote : nil } })
                            .padding()
                    }
                    .frame(minWidth: 420)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if onPage.isEmpty { Text("No concepts cite this slide.").foregroundStyle(.secondary) }
                            ForEach(onPage) { card($0) }
                        }
                        .padding()
                        .padding(.bottom, 160)
                    }
                    .frame(minWidth: 380)
                }
            }
        }
        .toolbar {
            ToolbarItem { Button("Previous", systemImage: "chevron.up") { step = max(1, step - 1) }.keyboardShortcut(.upArrow, modifiers: .command) }
            ToolbarItem { Button("Next", systemImage: "chevron.down") { step = min(groupStep, step + 1) }.keyboardShortcut(.downArrow, modifiers: .command) }
            ToolbarItem { ApproveButton() }
        }
        .sheet(item: $editing) { EditSheet(target: $0) }
    }

    private var onPage: [Candidate] { store.live.filter { $0.page == step } }

    private var strip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(1...groupStep, id: \.self) { s in
                    let open = s == groupStep
                        ? store.openFlags.filter { $0.type == .missingContrast }.count
                        : store.live.filter { $0.page == s }.flatMap { store.openFlags(for: $0.id) }.filter { $0.type != .missingContrast }.count
                    let count = s == groupStep ? 0 : store.live.filter { $0.page == s }.count
                    Button {
                        step = s
                    } label: {
                        VStack(spacing: 2) {
                            Text(s == groupStep ? "Methods" : "Slide \(s)").bold(s == step)
                            Text(open > 0 ? "⚠︎ \(open)" : s == groupStep ? "ok" : "\(count) concept\(count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(open > 0 ? .orange : .secondary)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .tint(s == step ? .accentColor : nil)
                }
            }
            .padding(8)
        }
    }

    private func card(_ c: Candidate) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(verbatim: c.title).font(.headline)
                    Text(c.kind.rawValue).foregroundStyle(.secondary)
                    Spacer()
                    Menu("Concept") { CandidateMenu(id: c.id, editing: $editing) }.fixedSize()
                }
                ForEach(store.flags(for: c.id).filter { $0.type != .missingContrast }) { flag in
                    VStack(alignment: .leading, spacing: 4) {
                        FlagHeader(flag: flag)
                        FlagActions(flag: flag)
                    }
                    .padding(6)
                    .background(.orange.opacity(0.08), in: .rect(cornerRadius: 6))
                }
                ForEach(c.claims) { ClaimRow(claim: $0) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
