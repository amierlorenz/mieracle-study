// PROTOTYPE — throwaway. Loads the real Gemini 3.8 Flash candidates from the extraction bake-off
// (MAT 305 Ch. 3 handout) and layers demo flags on top so every flag type shows up.
// Citation statuses are the real results of ocr-check.swift on that deck (3 text, 5 OCR, 3 miss).
import Foundation

enum SampleData {
    static let ocrVerified: Set<String> = [
        "Random Variable", "Discrete Sample Space", "Continuous Sample Space",
        "Cumulative Distribution Function of a Discrete Random Variable", "Probability Density Function",
    ]
    static let unverified: Set<String> = [
        "Probability Mass Function", "Cumulative Distribution Function of a Continuous Random Variable",
        "Relationship Between Continuous CDF and PDF",
    ]
    static let methods: Set<String> = [
        "Cumulative Distribution Function of a Discrete Random Variable",
        "Cumulative Distribution Function of a Continuous Random Variable",
        "Relationship Between Continuous CDF and PDF",
    ]

    struct Raw: Decodable {
        struct C: Decodable {
            var title: String
            var kind: String
            var definition: String
            var slide: Int
            var evidence: String
            var useWhen: [String]
            var confusedWith: [String]
            var gapFill: Bool
            var confidence: String
        }
        var concepts: [C]
    }

    static func load(from url: URL) throws -> ReviewStore {
        let raw = try JSONDecoder().decode(Raw.self, from: Data(contentsOf: url))
        var candidates = raw.concepts.map { c -> Candidate in
            let status: CitationStatus = unverified.contains(c.title) ? .unverified : ocrVerified.contains(c.title) ? .ocrVerified : .textVerified
            var claims = [Claim(label: "Definition", text: c.definition, provenance: c.gapFill ? .gapFill : .cited,
                                citation: Citation(page: c.slide, quote: c.evidence, status: status))]
            claims += c.useWhen.map {
                Claim(label: "Use when", text: $0, provenance: .cited, citation: Citation(page: c.slide, quote: "", status: .pageOnly))
            }
            let kind: Kind = methods.contains(c.title) ? .method : c.kind == "fact" ? .fact : .definition
            return Candidate(id: c.title, title: c.title, kind: kind, claims: claims, confusedWith: c.confusedWith)
        }

        func edit(_ title: String, _ body: (inout Candidate) -> Void) {
            if let i = candidates.firstIndex(where: { $0.id == title }) { body(&candidates[i]) }
        }
        edit("Continuous Sample Space") { $0.lowConfidenceDemo = true }
        edit("Probability Density Function") {
            $0.claims.append(Claim(label: "Use when", text: "Checking a density that exceeds 1 somewhere: that is allowed, only the total area must be 1.",
                                   provenance: .gapFill, demo: true))
            $0.enrichment = ExistingConcept(
                title: "PDF",
                note: "Library · MAT 305 · Unit 2 · unclassified, imported, 6 reviews, next due Oct 7",
                proposal: "Add kind = definition, the cited definition, and 4 cited cues to “PDF” instead of creating a duplicate. Its schedule and review history stay.")
        }
        edit("Relationship Between Continuous CDF and PDF") { $0.mergeWith = "Cumulative Distribution Function of a Continuous Random Variable" }
        edit("Cumulative Distribution Function of a Discrete Random Variable") {
            $0.claims.append(Claim(label: "Worked example",
                                   text: "Toss 3 coins, X = number of heads. 1. Write the pmf: f(0)=1/8, f(1)=3/8, f(2)=3/8, f(3)=1/8. 2. Sum f(t) for t ≤ x: F(1) = 1/8 + 3/8 = 1/2. 3. F is a step function, flat between outcomes.",
                                   provenance: .cited, citation: Citation(page: 4, quote: "", status: .pageOnly), demo: true))
        }

        let cdfD = "Cumulative Distribution Function of a Discrete Random Variable"
        let cdfC = "Cumulative Distribution Function of a Continuous Random Variable"
        let rel = "Relationship Between Continuous CDF and PDF"
        let group = MethodGroup(
            name: "Finding P(X ≤ x) and interval probabilities",
            question: "Which tool gives this probability?",
            members: [cdfD, cdfC, rel],
            contrasts: [
                Contrast(a: cdfD, b: cdfC, decidingFeature: Claim(
                    label: "Deciding feature",
                    text: "Countable outcomes → sum f(t) over t ≤ x. Values on a continuous scale → integrate f(t) from −∞ to x.",
                    provenance: .cited, citation: Citation(page: 6, quote: "", status: .pageOnly), demo: true)),
                Contrast(a: cdfC, b: rel, decidingFeature: nil),
            ])

        return ReviewStore(candidates: candidates, group: group, deckName: "Chapter 3 sections 3.1-3.3.pdf")
    }
}
