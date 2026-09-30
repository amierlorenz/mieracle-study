import Foundation

/// A problem found in an import document.
public struct ImportIssue: Hashable, Sendable, CustomStringConvertible {
    public enum Severity: String, Sendable {
        /// Blocks the import.
        case error
        /// Shown, but the import can proceed.
        case warning
    }

    public let severity: Severity
    /// Location in the document, such as `courses[0].units[1].concepts[2]`.
    public let path: String
    public let message: String

    public var description: String {
        "\(severity.rawValue): \(path): \(message)"
    }
}

/// Checks an ``ImportDocument`` for problems JSON decoding can't catch.
public struct ImportValidator: Sendable {
    /// Course ids already in the store, which exams may reference.
    public var knownCourseIDs: Set<String>
    /// Unit ids already in the store, which exams may reference.
    public var knownUnitIDs: Set<String>

    public init(knownCourseIDs: Set<String> = [], knownUnitIDs: Set<String> = []) {
        self.knownCourseIDs = knownCourseIDs
        self.knownUnitIDs = knownUnitIDs
    }

    public func validate(_ document: ImportDocument) -> [ImportIssue] {
        var issues: [ImportIssue] = []
        var seen: [String: [String: String]] = [:]

        func error(_ path: String, _ message: String) {
            issues.append(ImportIssue(severity: .error, path: path, message: message))
        }
        func warning(_ path: String, _ message: String) {
            issues.append(ImportIssue(severity: .warning, path: path, message: message))
        }
        func checkID(_ id: String, kind: String, at path: String) {
            if id.trimmingCharacters(in: .whitespaces).isEmpty {
                error(path, "\(kind) id is empty.")
            } else if let first = seen[kind]?[id] {
                error(path, "Duplicate \(kind) id \"\(id)\" (first used at \(first)).")
            } else {
                seen[kind, default: [:]][id] = path
            }
        }
        func requireText(_ text: String, _ field: String, at path: String) {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                error(path, "\(field) is empty.")
            }
        }

        if document.schemaVersion != MieracleKit.schemaVersion {
            error("schemaVersion", "Unsupported schema version \(document.schemaVersion); expected \(MieracleKit.schemaVersion).")
        }
        if document.courses.isEmpty && document.exams.isEmpty {
            warning("(root)", "The document contains no courses or exams.")
        }

        for (ci, course) in document.courses.enumerated() {
            let coursePath = "courses[\(ci)]"
            checkID(course.id, kind: "course", at: coursePath)
            requireText(course.name, "Course name", at: coursePath)

            for (ui, unit) in course.units.enumerated() {
                let unitPath = "\(coursePath).units[\(ui)]"
                checkID(unit.id, kind: "unit", at: unitPath)
                requireText(unit.name, "Unit name", at: unitPath)

                for (ki, concept) in unit.concepts.enumerated() {
                    let conceptPath = "\(unitPath).concepts[\(ki)]"
                    checkID(concept.id, kind: "concept", at: conceptPath)
                    requireText(concept.title, "Concept title", at: conceptPath)
                    if concept.prompts.isEmpty {
                        warning(conceptPath, "Concept has no prompts, so it can't be studied.")
                    }
                    for (ri, resource) in concept.resources.enumerated() where !["http", "https"].contains(resource.url.scheme ?? "") {
                        error("\(conceptPath).resources[\(ri)]", "Resource URL must be http or https.")
                    }
                    for (pi, prompt) in concept.prompts.enumerated() {
                        let promptPath = "\(conceptPath).prompts[\(pi)]"
                        checkID(prompt.id, kind: "prompt", at: promptPath)
                        for (path, message) in Self.problems(in: prompt.content) {
                            error(path.isEmpty ? promptPath : "\(promptPath).\(path)", message)
                        }
                    }
                }
            }
        }

        let courseIDs = Set(document.courses.map(\.id)).union(knownCourseIDs)
        let unitIDs = Set(document.courses.flatMap { $0.units.map(\.id) }).union(knownUnitIDs)
        for (ei, exam) in document.exams.enumerated() {
            let examPath = "exams[\(ei)]"
            checkID(exam.id, kind: "exam", at: examPath)
            requireText(exam.name, "Exam name", at: examPath)
            if !courseIDs.contains(exam.courseId) {
                error("\(examPath).courseId", "Unknown course id \"\(exam.courseId)\".")
            }
            if exam.parsedDate() == nil {
                error("\(examPath).date", "Date \"\(exam.date)\" must be YYYY-MM-DD or ISO 8601.")
            }
            for unitID in exam.unitIds where !unitIDs.contains(unitID) {
                error("\(examPath).unitIds", "Unknown unit id \"\(unitID)\".")
            }
            if exam.unitIds.isEmpty && exam.tags.isEmpty {
                warning(examPath, "Exam covers no units or tags yet; map them in the app.")
            }
        }

        return issues
    }

    /// Kind-specific problems as (relative path, message) pairs.
    static func problems(in content: PromptContent) -> [(String, String)] {
        var problems: [(String, String)] = []
        func requireText(_ text: String, _ field: String) {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                problems.append((field, "\(field) is empty."))
            }
        }
        func checkOptions(_ options: [String], _ correctIndex: Int) {
            if options.count < 2 {
                problems.append(("options", "Needs at least two options."))
            }
            if !options.indices.contains(correctIndex) {
                problems.append(("correctIndex", "Index \(correctIndex) is outside the \(options.count) options."))
            }
        }

        switch content {
        case .flashcard(let c):
            requireText(c.front, "front")
            requireText(c.back, "back")
        case .shortAnswer(let c):
            requireText(c.question, "question")
            requireText(c.modelAnswer, "modelAnswer")
        case .multipleChoice(let c):
            requireText(c.question, "question")
            checkOptions(c.options, c.correctIndex)
        case .codeImplement(let c):
            requireText(c.statement, "statement")
            if c.functionName.wholeMatch(of: /[A-Za-z_][A-Za-z0-9_]*/) == nil {
                problems.append(("functionName", "\"\(c.functionName)\" isn't a valid function name."))
            }
            if c.tests.isEmpty {
                problems.append(("tests", "Needs at least one test."))
            }
        case .codeComplexity(let c):
            requireText(c.code, "code")
            requireText(c.time, "time")
            requireText(c.space, "space")
        case .patternPick(let c):
            requireText(c.statement, "statement")
            requireText(c.answer, "answer")
            switch (c.options, c.correctIndex) {
            case (let options?, let index?):
                checkOptions(options, index)
            case (nil, nil):
                break
            default:
                problems.append(("options", "options and correctIndex must be given together."))
            }
        }
        return problems
    }
}

extension [ImportIssue] {
    public var hasErrors: Bool { contains { $0.severity == .error } }
}
