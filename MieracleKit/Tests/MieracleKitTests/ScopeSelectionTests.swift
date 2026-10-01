import MieracleKit
import Testing

struct ScopeSelectionTests {
    let catalog = ScopeCatalog(courses: [
        .init(id: "cs", units: [
            .init(id: "cs.a", conceptIDs: ["a1", "a2"]),
            .init(id: "cs.b", conceptIDs: ["b1"]),
        ]),
        .init(id: "math", units: [.init(id: "math.u", conceptIDs: ["m1"])]),
    ])

    @Test func togglingClassSelectsAndClearsIt() {
        var scope = SessionConfig.Scope()
        scope.toggleCourse("cs", in: catalog)
        #expect(scope.courseIDs == ["cs"])
        #expect(scope.state(ofCourse: "cs", in: catalog) == .all)
        scope.toggleCourse("cs", in: catalog)
        #expect(scope.isEmpty)
    }

    @Test func deselectingOneUnitOfSelectedClassKeepsTheRest() {
        var scope = SessionConfig.Scope(courseIDs: ["cs"])
        scope.toggleUnit("cs.a", inCourse: "cs", in: catalog)
        #expect(scope.courseIDs.isEmpty)
        #expect(scope.unitIDs == ["cs.b"])
        #expect(scope.state(ofCourse: "cs", in: catalog) == .some)
    }

    @Test func selectingEveryUnitCollapsesToTheClass() {
        var scope = SessionConfig.Scope()
        scope.toggleUnit("cs.a", inCourse: "cs", in: catalog)
        scope.toggleUnit("cs.b", inCourse: "cs", in: catalog)
        #expect(scope.courseIDs == ["cs"])
        #expect(scope.unitIDs.isEmpty)
    }

    @Test func conceptSelectionIsPartialUntilComplete() {
        var scope = SessionConfig.Scope()
        scope.toggleConcept("a1", unitID: "cs.a", courseID: "cs", in: catalog)
        #expect(scope.state(ofUnit: "cs.a", inCourse: "cs", in: catalog) == .some)
        #expect(scope.selectedConceptCount(inCourse: "cs", in: catalog) == 1)

        scope.toggleConcept("a2", unitID: "cs.a", courseID: "cs", in: catalog)
        #expect(scope.unitIDs == ["cs.a"])
        #expect(scope.conceptIDs.isEmpty)
    }

    @Test func deselectingConceptInSelectedClassExpandsSelection() {
        var scope = SessionConfig.Scope(courseIDs: ["cs"])
        scope.toggleConcept("a1", unitID: "cs.a", courseID: "cs", in: catalog)
        #expect(scope.unitIDs == ["cs.b"])
        #expect(scope.conceptIDs == ["a2"])
        #expect(scope.selectedConceptCount(inCourse: "cs", in: catalog) == 2)
    }

    @Test func selectAllAndDeselectAll() {
        var scope = SessionConfig.Scope(conceptIDs: ["a1"])
        scope.selectAll(in: catalog)
        #expect(scope.courseIDs == ["cs", "math"])
        #expect(scope.conceptIDs.isEmpty)
        scope.deselectAll()
        #expect(scope.isEmpty)
    }
}
