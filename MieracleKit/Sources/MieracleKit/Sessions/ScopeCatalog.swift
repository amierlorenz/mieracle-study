/// The class → unit → concept tree a session scope is chosen from.
public struct ScopeCatalog: Sendable, Equatable {
    public struct CourseEntry: Sendable, Equatable, Identifiable {
        public var id: String
        public var units: [UnitEntry]

        public init(id: String, units: [UnitEntry]) {
            self.id = id
            self.units = units
        }

        var conceptIDs: [String] { units.flatMap(\.conceptIDs) }
    }

    public struct UnitEntry: Sendable, Equatable, Identifiable {
        public var id: String
        public var conceptIDs: [String]

        public init(id: String, conceptIDs: [String]) {
            self.id = id
            self.conceptIDs = conceptIDs
        }
    }

    public var courses: [CourseEntry]

    public init(courses: [CourseEntry]) {
        self.courses = courses
    }

    @MainActor
    public init(models courses: [Course]) {
        self.courses = courses.map { course in
            CourseEntry(id: course.externalID, units: course.sortedUnits.map { unit in
                UnitEntry(id: unit.externalID, conceptIDs: (unit.concepts ?? []).map(\.externalID))
            })
        }
    }

    func course(_ id: String) -> CourseEntry? { courses.first { $0.id == id } }
}

/// How much of a class or unit is selected.
public enum SelectionState: Sendable, Equatable {
    case none
    case some
    case all
}

extension SessionConfig.Scope {
    public func state(ofCourse courseID: String, in catalog: ScopeCatalog) -> SelectionState {
        guard let course = catalog.course(courseID) else { return .none }
        if courseIDs.contains(courseID) { return .all }
        let states = course.units.map { state(ofUnit: $0, in: course) }
        if !states.isEmpty, states.allSatisfy({ $0 == .all }) { return .all }
        return states.contains { $0 != .none } ? .some : .none
    }

    public func state(ofUnit unitID: String, inCourse courseID: String, in catalog: ScopeCatalog) -> SelectionState {
        guard let course = catalog.course(courseID), let unit = course.units.first(where: { $0.id == unitID }) else { return .none }
        return state(ofUnit: unit, in: course)
    }

    public func isSelected(concept conceptID: String, unitID: String, courseID: String) -> Bool {
        courseIDs.contains(courseID) || unitIDs.contains(unitID) || conceptIDs.contains(conceptID)
    }

    /// Number of concepts selected in a class.
    public func selectedConceptCount(inCourse courseID: String, in catalog: ScopeCatalog) -> Int {
        guard let course = catalog.course(courseID) else { return 0 }
        return course.units.reduce(0) { total, unit in
            total + unit.conceptIDs.count { isSelected(concept: $0, unitID: unit.id, courseID: courseID) }
        }
    }

    public mutating func toggleCourse(_ courseID: String, in catalog: ScopeCatalog) {
        guard let course = catalog.course(courseID) else { return }
        let wasAll = state(ofCourse: courseID, in: catalog) == .all
        clear(course)
        if !wasAll { courseIDs.insert(courseID) }
    }

    public mutating func toggleUnit(_ unitID: String, inCourse courseID: String, in catalog: ScopeCatalog) {
        guard let course = catalog.course(courseID), let unit = course.units.first(where: { $0.id == unitID }) else { return }
        let wasAll = state(ofUnit: unit, in: course) == .all
        expandCourse(course)
        unitIDs.remove(unit.id)
        conceptIDs.subtract(unit.conceptIDs)
        if !wasAll { unitIDs.insert(unit.id) }
        collapse(course)
    }

    public mutating func toggleConcept(_ conceptID: String, unitID: String, courseID: String, in catalog: ScopeCatalog) {
        guard let course = catalog.course(courseID), let unit = course.units.first(where: { $0.id == unitID }) else { return }
        let wasSelected = isSelected(concept: conceptID, unitID: unitID, courseID: courseID)
        expandCourse(course)
        if unitIDs.remove(unit.id) != nil {
            conceptIDs.formUnion(unit.conceptIDs)
        }
        if wasSelected {
            conceptIDs.remove(conceptID)
        } else {
            conceptIDs.insert(conceptID)
        }
        collapse(course)
    }

    /// Selects or clears every concept in one class.
    public mutating func setCourse(_ courseID: String, selected: Bool, in catalog: ScopeCatalog) {
        guard let course = catalog.course(courseID) else { return }
        clear(course)
        if selected { courseIDs.insert(courseID) }
    }

    public mutating func selectAll(in catalog: ScopeCatalog) {
        unitIDs = []
        conceptIDs = []
        courseIDs = Set(catalog.courses.map(\.id))
    }

    public mutating func deselectAll() {
        courseIDs = []
        unitIDs = []
        conceptIDs = []
        tags = []
    }

    private func state(ofUnit unit: ScopeCatalog.UnitEntry, in course: ScopeCatalog.CourseEntry) -> SelectionState {
        if courseIDs.contains(course.id) || unitIDs.contains(unit.id) { return .all }
        let selected = unit.conceptIDs.count { conceptIDs.contains($0) }
        if selected == 0 { return .none }
        return selected == unit.conceptIDs.count ? .all : .some
    }

    private mutating func clear(_ course: ScopeCatalog.CourseEntry) {
        courseIDs.remove(course.id)
        unitIDs.subtract(course.units.map(\.id))
        conceptIDs.subtract(course.conceptIDs)
    }

    /// Replaces a whole-class selection with its units, so one part can change.
    private mutating func expandCourse(_ course: ScopeCatalog.CourseEntry) {
        if courseIDs.remove(course.id) != nil {
            unitIDs.formUnion(course.units.map(\.id))
        }
    }

    /// Folds complete units and classes back into single ids.
    private mutating func collapse(_ course: ScopeCatalog.CourseEntry) {
        for unit in course.units where !unit.conceptIDs.isEmpty && unit.conceptIDs.allSatisfy(conceptIDs.contains) {
            conceptIDs.subtract(unit.conceptIDs)
            unitIDs.insert(unit.id)
        }
        if !course.units.isEmpty, course.units.allSatisfy({ unitIDs.contains($0.id) }) {
            unitIDs.subtract(course.units.map(\.id))
            courseIDs.insert(course.id)
        }
    }
}
