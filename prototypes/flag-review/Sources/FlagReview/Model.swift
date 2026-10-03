// PROTOTYPE — throwaway. In-memory review state; nothing is persisted.
import Foundation
import Observation

enum Provenance: String { case cited, gapFill, userWritten }

enum CitationStatus: String {
    case textVerified = "verified (PDF text)"
    case ocrVerified = "verified (OCR)"
    case pageOnly = "slide only, no quote"
    case unverified = "unverified"
    case confirmedByYou = "confirmed by you"
}

struct Citation: Hashable {
    var page: Int
    var quote: String
    var status: CitationStatus
}

struct Claim: Identifiable, Hashable {
    let id = UUID()
    var label: String
    var text: String
    var provenance: Provenance
    var citation: Citation?
    var demo = false
}

enum Kind: String, CaseIterable { case definition, fact, method }

struct ExistingConcept: Hashable {
    var title: String
    var note: String
    var proposal: String
}

struct Candidate: Identifiable {
    let id: String
    var title: String
    var kind: Kind
    var claims: [Claim]
    var confusedWith: [String]
    var lowConfidenceDemo = false
    var enrichment: ExistingConcept?
    var mergeWith: String?
    var page: Int { claims.first?.citation?.page ?? 1 }
    var definition: Claim? { claims.first { $0.label == "Definition" } }
}

enum FlagType: String, CaseIterable {
    case citationUnverified = "Citation unverified"
    case gapFill = "Gap-fill claim"
    case enrichment = "Matches an existing concept"
    case merge = "Possible duplicate in this run"
    case lowConfidence = "Low confidence"
    case missingExample = "Method has no worked example"
    case missingContrast = "Confusable pair has no contrast"

    var symbol: String {
        switch self {
        case .citationUnverified: "quote.bubble"
        case .gapFill: "puzzlepiece"
        case .enrichment: "arrow.triangle.merge"
        case .merge: "square.on.square"
        case .lowConfidence: "questionmark.circle"
        case .missingExample: "list.number"
        case .missingContrast: "arrow.left.arrow.right"
        }
    }
}

struct Flag: Identifiable, Hashable {
    var type: FlagType
    var candidateID: String?
    var claimID: UUID?
    var pair: [String] = []
    var demo: Bool
    var id: String { [type.rawValue, candidateID ?? "", claimID?.uuidString ?? "", pair.joined(separator: "+")].joined(separator: "|") }
}

enum Resolution: String {
    case kept = "Kept as is"
    case edited = "Edited"
    case confirmed = "Quote confirmed"
    case removedClaim = "Claim removed"
    case dropped = "Concept dropped"
    case merged = "Merged"
    case enriched = "Enriched the existing concept"
    case keptSeparate = "Kept as a new concept"
    case written = "You wrote it"
    case skipped = "Skipped"
}

struct Contrast: Identifiable {
    let id = UUID()
    var a: String
    var b: String
    var decidingFeature: Claim?
}

struct MethodGroup {
    var name: String
    var question: String
    var members: [String]
    var contrasts: [Contrast]
}

@Observable
final class ReviewStore {
    var candidates: [Candidate]
    var group: MethodGroup
    var resolutions: [String: Resolution] = [:]
    var dropped: Set<String> = []
    var mergedInto: [String: String] = [:]
    var log: [String] = []
    var approved = false
    let deckName: String

    init(candidates: [Candidate], group: MethodGroup, deckName: String) {
        self.candidates = candidates
        self.group = group
        self.deckName = deckName
    }

    var live: [Candidate] { candidates.filter { !dropped.contains($0.id) && mergedInto[$0.id] == nil } }

    func candidate(_ id: String) -> Candidate? { candidates.first { $0.id == id } }
    func title(_ id: String) -> String { candidate(id)?.title ?? id }

    var allFlags: [Flag] {
        var flags: [Flag] = []
        for c in live {
            for claim in c.claims {
                if claim.citation?.status == .unverified {
                    flags.append(Flag(type: .citationUnverified, candidateID: c.id, claimID: claim.id, demo: claim.demo))
                }
                if claim.provenance == .gapFill {
                    flags.append(Flag(type: .gapFill, candidateID: c.id, claimID: claim.id, demo: claim.demo))
                }
            }
            if c.enrichment != nil { flags.append(Flag(type: .enrichment, candidateID: c.id, demo: true)) }
            if let other = c.mergeWith, live.contains(where: { $0.id == other }) {
                flags.append(Flag(type: .merge, candidateID: c.id, pair: [c.id, other], demo: true))
            }
            if c.lowConfidenceDemo { flags.append(Flag(type: .lowConfidence, candidateID: c.id, demo: true)) }
            if c.kind == .method, !c.claims.contains(where: { $0.label == "Worked example" }) {
                flags.append(Flag(type: .missingExample, candidateID: c.id, demo: false))
            }
        }
        for contrast in group.contrasts where contrast.decidingFeature == nil {
            guard live.contains(where: { $0.id == contrast.a }), live.contains(where: { $0.id == contrast.b }) else { continue }
            flags.append(Flag(type: .missingContrast, pair: [contrast.a, contrast.b], demo: false))
        }
        return flags
    }

    var openFlags: [Flag] { allFlags.filter { resolutions[$0.id] == nil } }
    func flags(for id: String) -> [Flag] { allFlags.filter { $0.candidateID == id || $0.pair.contains(id) } }
    func openFlags(for id: String) -> [Flag] { flags(for: id).filter { resolutions[$0.id] == nil } }
    var unflagged: [Candidate] { live.filter { flags(for: $0.id).isEmpty } }

    func page(of flag: Flag) -> Int {
        if let cid = flag.candidateID, let c = candidate(cid) {
            if let claimID = flag.claimID, let page = c.claims.first(where: { $0.id == claimID })?.citation?.page { return page }
            return c.page
        }
        return flag.pair.first.flatMap { candidate($0)?.page } ?? 1
    }

    func quote(of flag: Flag) -> String? {
        guard let cid = flag.candidateID, let c = candidate(cid) else { return nil }
        if let claimID = flag.claimID { return c.claims.first { $0.id == claimID }?.citation?.quote }
        return c.definition?.citation?.quote
    }

    func resolve(_ flag: Flag, _ resolution: Resolution) {
        resolutions[flag.id] = resolution
        record("\(flag.type.rawValue) · \(flag.candidateID.map(title) ?? flag.pair.map(title).joined(separator: " ↔ ")) → \(resolution.rawValue)")
    }

    func unresolve(_ flag: Flag) {
        resolutions[flag.id] = nil
        record("Undo: \(flag.type.rawValue)")
    }

    private func index(_ id: String) -> Int { candidates.firstIndex { $0.id == id }! }

    func rename(_ id: String, to title: String) {
        guard !title.isEmpty, title != candidates[index(id)].title else { return }
        record("Renamed \(candidates[index(id)].title) → \(title)")
        candidates[index(id)].title = title
    }

    func setKind(_ id: String, _ kind: Kind) {
        candidates[index(id)].kind = kind
        record("Kind of \(title(id)) → \(kind.rawValue)")
    }

    func drop(_ id: String) {
        dropped.insert(id)
        record("Dropped \(title(id))")
    }

    func restore(_ id: String) {
        dropped.remove(id)
        mergedInto[id] = nil
        record("Restored \(title(id))")
    }

    func merge(_ source: String, into target: String) {
        let src = candidates[index(source)]
        let t = index(target)
        let carried = src.claims.filter { $0.label != "Definition" }
        candidates[t].claims.append(contentsOf: carried)
        if let def = src.definition {
            var extra = def
            extra.label = "Also from \(src.title)"
            candidates[t].claims.append(extra)
        }
        mergedInto[source] = target
        record("Merged \(src.title) into \(title(target)) (+\(carried.count + 1) claims)")
    }

    func updateClaim(_ cid: String, _ claimID: UUID, text: String) {
        let c = index(cid)
        guard let k = candidates[c].claims.firstIndex(where: { $0.id == claimID }) else { return }
        candidates[c].claims[k].text = text
        if candidates[c].claims[k].provenance == .gapFill { candidates[c].claims[k].provenance = .userWritten }
        record("Edited \(candidates[c].claims[k].label.lowercased()) of \(candidates[c].title)")
    }

    func confirmQuote(_ cid: String, _ claimID: UUID) {
        let c = index(cid)
        guard let k = candidates[c].claims.firstIndex(where: { $0.id == claimID }) else { return }
        candidates[c].claims[k].citation?.status = .confirmedByYou
    }

    func removeClaim(_ cid: String, _ claimID: UUID) {
        let c = index(cid)
        candidates[c].claims.removeAll { $0.id == claimID }
        record("Removed a claim from \(candidates[c].title)")
    }

    func addClaim(_ cid: String, label: String, text: String) {
        candidates[index(cid)].claims.append(Claim(label: label, text: text, provenance: .userWritten))
        record("Wrote \(label.lowercased()) for \(title(cid))")
    }

    func setContrast(_ contrastID: UUID, text: String) {
        guard let k = group.contrasts.firstIndex(where: { $0.id == contrastID }) else { return }
        group.contrasts[k].decidingFeature = Claim(label: "Deciding feature", text: text, provenance: .userWritten)
        record("Wrote contrast \(title(group.contrasts[k].a)) ↔ \(title(group.contrasts[k].b))")
    }

    func record(_ line: String) { log.insert(line, at: 0) }

    var summary: [String] {
        let open = openFlags
        let enriched = live.filter { c in resolutions[Flag(type: .enrichment, candidateID: c.id, demo: true).id] == .enriched }
        var lines = [
            "\(live.count - enriched.count) new Concept rows (origin = intake, approvedAt = now)",
            "\(enriched.count) existing concepts enriched",
            "\(dropped.count) dropped, \(mergedInto.count) merged away",
            "1 MethodGroup “\(group.name)” with \(group.contrasts.filter { $0.decidingFeature != nil }.count)/\(group.contrasts.count) contrasts written",
            "\(open.count) flags still open → accepted as is",
        ]
        let gap = live.flatMap(\.claims).filter { $0.provenance == .gapFill }.count
        if gap > 0 { lines.append("\(gap) claims stay labelled gap-fill") }
        return lines
    }
}
