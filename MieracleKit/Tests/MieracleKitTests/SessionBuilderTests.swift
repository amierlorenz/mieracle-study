import Foundation
import MieracleKit
import Testing

struct SessionBuilderTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    var yesterday: Date { now.addingTimeInterval(-86_400) }
    var tomorrow: Date { now.addingTimeInterval(86_400) }

    func concept(
        _ id: String,
        unit: String = "u1",
        course: String = "c1",
        sort: Int = 1,
        tags: Set<String> = [],
        isNew: Bool = false,
        due: Date? = nil,
        ease: Double = 2.5,
        lapses: Int = 0,
        prompts: [PromptSnapshot]? = nil
    ) -> ConceptSnapshot {
        ConceptSnapshot(
            id: id, courseID: course, unitID: unit, unitSortIndex: sort, tags: tags, isNew: isNew,
            dueDate: due ?? (isNew ? nil : yesterday), ease: ease, lapses: lapses,
            prompts: prompts ?? [PromptSnapshot(id: "\(id).p", kind: .flashcard)]
        )
    }

    func build(_ candidates: [ConceptSnapshot], _ config: SessionConfig, newRemaining: Int = 15, code: Bool = true, seed: UInt64 = 1) -> [SessionItem] {
        var rng = SeededGenerator(seed: seed)
        return SessionBuilder(config: config, newRemaining: newRemaining, supportsCodeExecution: code).build(from: candidates, now: now, using: &rng)
    }

    @Test func reviewTakesOnlyDueStudiedConcepts() {
        let items = build([
            concept("due"),
            concept("later", due: tomorrow),
            concept("new", isNew: true),
        ], .init(mode: .review))
        #expect(items.map(\.conceptID) == ["due"])
    }

    @Test func learnNewIsCappedByBudgetInUnitOrder() {
        let items = build([
            concept("b1", unit: "b", sort: 2, isNew: true),
            concept("a1", unit: "a", sort: 1, isNew: true),
            concept("a2", unit: "a", sort: 1, isNew: true),
            concept("old"),
        ], .init(mode: .learnNew, order: .blocked), newRemaining: 2)
        #expect(Set(items.map(\.conceptID)) == ["a1", "a2"])
    }

    @Test func practiceIncludesEverythingInScope() {
        let items = build([concept("due"), concept("later", due: tomorrow), concept("new", isNew: true)], .init(mode: .practice))
        #expect(items.count == 3)
    }

    @Test func scopeMatchesCourseUnitOrTag() {
        let candidates = [
            concept("course", course: "c2"),
            concept("unit", unit: "u9"),
            concept("tag", tags: ["exam2"]),
            concept("other"),
        ]
        let scope = SessionConfig.Scope(courseIDs: ["c2"], unitIDs: ["u9"], tags: ["exam2"])
        let items = build(candidates, .init(scope: scope, mode: .practice))
        #expect(Set(items.map(\.conceptID)) == ["course", "unit", "tag"])
    }

    @Test func excludesFlaggedFilteredAndUnsupportedPrompts() {
        let candidates = [
            concept("flagged", prompts: [.init(id: "f", kind: .flashcard, isFlagged: true)]),
            concept("code", prompts: [.init(id: "c", kind: .codeImplement)]),
            concept("mc", prompts: [.init(id: "m", kind: .multipleChoice)]),
            concept("mixed", prompts: [.init(id: "x1", kind: .codeImplement), .init(id: "x2", kind: .flashcard)]),
        ]
        let items = build(candidates, .init(mode: .practice, promptKinds: [.flashcard, .codeImplement]), code: false)
        #expect(items.map(\.promptID) == ["x2"])
    }

    @Test func picksLeastRecentlyShownPrompt() {
        let prompts: [PromptSnapshot] = [
            .init(id: "recent", kind: .flashcard, lastShownAt: now),
            .init(id: "never", kind: .shortAnswer),
            .init(id: "old", kind: .multipleChoice, lastShownAt: yesterday),
        ]
        #expect(build([concept("k", prompts: prompts)], .init(mode: .practice)).first?.promptID == "never")
    }

    @Test(arguments: 1...20)
    func interleavingAvoidsConsecutiveUnits(seed: Int) {
        let candidates = (0..<4).map { concept("a\($0)", unit: "a") } + (0..<3).map { concept("b\($0)", unit: "b") } + (0..<2).map { concept("c\($0)", unit: "c") }
        let units = build(candidates, .init(mode: .practice), seed: UInt64(seed)).map(\.unitID)
        #expect(units.count == 9)
        #expect(zip(units, units.dropFirst()).allSatisfy { $0 != $1 })
    }

    @Test func interleavingRepeatsOnlyWhenForced() {
        let candidates = (0..<3).map { concept("a\($0)", unit: "a") } + [concept("b0", unit: "b")]
        let units = build(candidates, .init(mode: .practice)).map(\.unitID)
        #expect(units == ["a", "b", "a", "a"])
    }

    @Test func blockedGroupsUnitsInCourseOrder() {
        let candidates = [concept("b0", unit: "b", sort: 2), concept("a0", unit: "a", sort: 1), concept("b1", unit: "b", sort: 2), concept("a1", unit: "a", sort: 1)]
        #expect(build(candidates, .init(mode: .practice, order: .blocked)).map(\.unitID) == ["a", "a", "b", "b"])
    }

    @Test func hardestFirstSortsByEaseThenLapses() {
        let candidates = [concept("easy", ease: 2.8), concept("hard", ease: 1.3, lapses: 1), concept("hardest", ease: 1.3, lapses: 4), concept("mid", ease: 2.0)]
        #expect(build(candidates, .init(mode: .practice, order: .hardestFirst)).map(\.conceptID) == ["hardest", "hard", "mid", "easy"])
    }

    @Test func countLimitKeepsMostOverdueReviews() {
        let candidates = [
            concept("week", due: now.addingTimeInterval(-7 * 86_400)),
            concept("day", due: yesterday),
            concept("month", due: now.addingTimeInterval(-30 * 86_400)),
        ]
        let items = build(candidates, .init(mode: .review, length: .count(2)))
        #expect(Set(items.map(\.conceptID)) == ["week", "month"])
    }

    @Test func configRoundTripsThroughData() {
        let config = SessionConfig(scope: .init(unitIDs: ["u1"]), mode: .learnNew, length: .minutes(25), order: .blocked, promptKinds: [.flashcard])
        #expect(SessionConfig.decoded(from: config.encoded()) == config)
    }
}
