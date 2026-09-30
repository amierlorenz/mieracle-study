/// What an import will do, or did, to the store.
public struct ImportPlan: Equatable, Sendable {
    public struct Counts: Equatable, Sendable {
        public var new = 0
        public var updated = 0
        public var unchanged = 0

        public init(new: Int = 0, updated: Int = 0, unchanged: Int = 0) {
            self.new = new
            self.updated = updated
            self.unchanged = unchanged
        }
    }

    public var courses = Counts()
    public var units = Counts()
    public var concepts = Counts()
    public var prompts = Counts()
    public var exams = Counts()
    public var issues: [ImportIssue] = []

    public init() {}

    public var canApply: Bool { !issues.hasErrors }

    /// Whether applying would change anything.
    public var hasChanges: Bool {
        [courses, units, concepts, prompts, exams].contains { $0.new > 0 || $0.updated > 0 }
    }
}
