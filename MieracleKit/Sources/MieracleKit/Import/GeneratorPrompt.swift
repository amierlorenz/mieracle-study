import Foundation

/// Builds the instructions pasted into an external AI, together with slides or
/// notes, to produce an import file.
public struct GeneratorPrompt: Sendable {
    public struct UnitReference: Hashable, Sendable {
        public var id: String
        public var name: String

        public init(id: String, name: String) {
            self.id = id
            self.name = name
        }
    }

    public var courseID: String
    public var courseName: String
    public var units: [UnitReference]
    /// Concept ids that already exist, so the AI updates instead of duplicating them.
    public var existingConceptIDs: [String]

    public init(courseID: String, courseName: String, units: [UnitReference] = [], existingConceptIDs: [String] = []) {
        self.courseID = courseID
        self.courseName = courseName
        self.units = units
        self.existingConceptIDs = existingConceptIDs
    }

    /// Lowercase, hyphenated form of a name, suitable for ids.
    public static func slug(_ text: String) -> String {
        let pieces = text.lowercased().split { !($0.isLetter || $0.isNumber) }
        return pieces.joined(separator: "-")
    }

    public var text: String {
        """
        You are turning course material into study content for MieracleStudy, a spaced-repetition app built on the research in *Make It Stick*. Read the attached slides, notes, or documents and produce ONE JSON file that follows the format below. Output only the JSON in a single ```json code block.

        ## Course
        - Course id: `\(courseID)`
        - Course name: \(courseName)
        \(unitSection)
        \(existingSection)
        ## What to extract
        - Every idea a student could be tested on: definitions, mechanisms, reasons, comparisons, formulas, procedures, examples, and common mistakes. Include important material the notes skip if the slides cover it.
        - Skip logistics (due dates, grading policy, office hours).
        - One idea per concept. A concept's `title` is a short name; its `explanation` is 2–5 sentences of Markdown that teach the idea and say why it matters.

        ## Prompts (2–4 per concept, mixed types)
        - Favor recall over recognition: at least one `flashcard` or `shortAnswer` per concept.
        - Include "why" or "how" questions, not only "what".
        - `shortAnswer`: a model answer plus 2–4 `keyPoints` a correct answer must mention.
        - `multipleChoice`: 3–5 options; wrong options are plausible misconceptions, not jokes.
        - Programming material: `codeImplement` (Python function with test cases), `codeComplexity` (Big-O of a snippet), and `patternPick` (choose the approach or data structure, with the reason in `explanation`).
        - Math uses LaTeX: `$inline$` and `$$display$$`. Code uses fenced blocks. Escape backslashes for JSON (`\\\\frac`).
        - Every prompt must be answerable from the concept's explanation or the material.

        ## Ids
        - Stable, lowercase, kebab-case, prefixed by the parent's id: unit `\(courseID).<unit-slug>`, concept `<unit-id>.<concept-slug>`, prompt `<concept-id>.<type>-<n>`.
        - Reuse an existing id exactly when revising something that already exists. Never reuse an id for a different idea.

        ## Resources and exams
        - `resources`: only well-known, stable URLs you are confident exist (official docs, textbooks, reputable tutorials). Omit rather than guess.
        - `exams`: include only if the material states an exam date; list the unit ids it covers.

        ## Format (schemaVersion 1)
        ```json
        {
          "schemaVersion": 1,
          "courses": [{
            "id": "\(courseID)", "name": "\(courseName)",
            "units": [{
              "id": "\(courseID).unit-slug", "name": "Unit name", "order": 1,
              "concepts": [{
                "id": "\(courseID).unit-slug.concept-slug",
                "title": "Short name",
                "explanation": "Markdown with $math$ and `code`.",
                "tags": ["optional-tag"],
                "resources": [{"title": "Docs", "url": "https://…"}],
                "prompts": [
                  {"id": "….flashcard-1", "type": "flashcard", "front": "…", "back": "…"},
                  {"id": "….shortAnswer-1", "type": "shortAnswer", "question": "…", "modelAnswer": "…", "keyPoints": ["…", "…"]},
                  {"id": "….multipleChoice-1", "type": "multipleChoice", "question": "…", "options": ["…", "…", "…"], "correctIndex": 0, "explanation": "…"},
                  {"id": "….codeImplement-1", "type": "codeImplement", "statement": "…", "functionName": "solve", "starterCode": "def solve(nums):\\n    pass", "tests": [{"args": [[1, 2]], "expected": 3}, {"args": [[]], "expected": 0, "hidden": true}], "comparison": "exact"},
                  {"id": "….codeComplexity-1", "type": "codeComplexity", "code": "…", "time": "O(n log n)", "space": "O(n)", "explanation": "…"},
                  {"id": "….patternPick-1", "type": "patternPick", "statement": "…", "options": ["…", "…"], "correctIndex": 0, "answer": "…", "explanation": "…"}
                ]
              }]
            }]
          }],
          "exams": [{"id": "\(courseID).midterm-1", "courseId": "\(courseID)", "name": "Midterm 1", "date": "YYYY-MM-DD", "unitIds": ["\(courseID).unit-slug"]}]
        }
        ```
        Field notes: `comparison` is `exact`, `unordered` (lists in any order), or `float`. `tests[].args` are positional arguments. `patternPick` without `options`/`correctIndex` is graded as free text against `answer`. Optional fields may be omitted.
        """
    }

    private var unitSection: String {
        guard !units.isEmpty else {
            return "- No units exist yet. Create units that match the material's structure.\n"
        }
        let list = units.map { "  - `\($0.id)` — \($0.name)" }.joined(separator: "\n")
        return "- Existing units (reuse these ids; add new units only if needed):\n\(list)\n"
    }

    private var existingSection: String {
        guard !existingConceptIDs.isEmpty else { return "" }
        let list = existingConceptIDs.sorted().map { "`\($0)`" }.joined(separator: ", ")
        return "- Existing concept ids (reuse when revising the same idea): \(list)\n"
    }
}
