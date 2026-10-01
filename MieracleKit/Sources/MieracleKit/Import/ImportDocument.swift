import Foundation

/// The import/export file format (schema v1).
///
/// Every entity carries a stable `id`. Importing a document whose ids already
/// exist updates those records in place and keeps their review history.
public struct ImportDocument: Codable, Hashable, Sendable {
    public var schemaVersion: Int
    public var courses: [Course]
    public var exams: [Exam]

    public init(schemaVersion: Int = MieracleKit.schemaVersion, courses: [Course], exams: [Exam] = []) {
        self.schemaVersion = schemaVersion
        self.courses = courses
        self.exams = exams
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        courses = try c.decodeIfPresent([Course].self, forKey: .courses) ?? []
        exams = try c.decodeIfPresent([Exam].self, forKey: .exams) ?? []
    }

    /// Decodes a document, turning decoding failures into readable messages.
    public static func decode(from data: Data) throws(ImportDecodingError) -> ImportDocument {
        do {
            return try JSONDecoder().decode(ImportDocument.self, from: data)
        } catch let error as DecodingError {
            throw ImportDecodingError(error)
        } catch {
            throw ImportDecodingError(message: error.localizedDescription)
        }
    }

    /// Decodes a document from pasted text, ignoring anything around the outermost
    /// JSON object (such as a Markdown code fence).
    public static func decode(fromPasted text: String) throws(ImportDecodingError) -> ImportDocument {
        guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}"), start < end else {
            throw ImportDecodingError(message: "No JSON object found in the pasted text.")
        }
        return try decode(from: Data(text[start...end].utf8))
    }

    /// Encodes with stable, human-readable formatting.
    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }
}

extension ImportDocument {
    public struct Course: Codable, Hashable, Sendable {
        public var id: String
        public var name: String
        /// A compact label such as "CSC 395 | Swift".
        public var shortName: String?
        /// Whether coding prompt kinds belong in this class. Implied when any prompt is a coding kind.
        public var coding: Bool?
        public var units: [Unit]

        public init(id: String, name: String, shortName: String? = nil, coding: Bool? = nil, units: [Unit]) {
            self.id = id
            self.name = name
            self.shortName = shortName
            self.coding = coding
            self.units = units
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            name = try c.decode(String.self, forKey: .name)
            shortName = try c.decodeIfPresent(String.self, forKey: .shortName)
            coding = try c.decodeIfPresent(Bool.self, forKey: .coding)
            units = try c.decodeIfPresent([Unit].self, forKey: .units) ?? []
        }

        /// Whether the class should allow coding kinds after import.
        public var impliesCoding: Bool {
            coding ?? units.contains { $0.concepts.contains { $0.prompts.contains { $0.content.kind.isCoding } } }
        }
    }

    public struct Unit: Codable, Hashable, Sendable {
        public var id: String
        public var name: String
        /// Position within the course; defaults to the unit's position in the file.
        public var order: Int?
        public var concepts: [Concept]

        public init(id: String, name: String, order: Int? = nil, concepts: [Concept]) {
            self.id = id
            self.name = name
            self.order = order
            self.concepts = concepts
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            name = try c.decode(String.self, forKey: .name)
            order = try c.decodeIfPresent(Int.self, forKey: .order)
            concepts = try c.decodeIfPresent([Concept].self, forKey: .concepts) ?? []
        }
    }

    public struct Concept: Codable, Hashable, Sendable {
        public var id: String
        public var title: String
        public var explanation: String
        public var tags: [String]
        public var resources: [Resource]
        public var prompts: [Prompt]

        public init(id: String, title: String, explanation: String, tags: [String] = [], resources: [Resource] = [], prompts: [Prompt]) {
            self.id = id
            self.title = title
            self.explanation = explanation
            self.tags = tags
            self.resources = resources
            self.prompts = prompts
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            title = try c.decode(String.self, forKey: .title)
            explanation = try c.decodeIfPresent(String.self, forKey: .explanation) ?? ""
            tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
            resources = try c.decodeIfPresent([Resource].self, forKey: .resources) ?? []
            prompts = try c.decodeIfPresent([Prompt].self, forKey: .prompts) ?? []
        }
    }

    /// A prompt: an `id` plus the flat, `type`-discriminated fields of ``PromptContent``.
    public struct Prompt: Codable, Hashable, Sendable {
        public var id: String
        public var content: PromptContent

        public init(id: String, content: PromptContent) {
            self.id = id
            self.content = content
        }

        private enum CodingKeys: String, CodingKey {
            case id
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            content = try PromptContent(from: decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(id, forKey: .id)
            try content.encode(to: encoder)
        }
    }

    public struct Exam: Codable, Hashable, Sendable {
        public var id: String
        public var courseId: String
        public var name: String
        /// `YYYY-MM-DD` (local start of day) or a full ISO 8601 timestamp.
        public var date: String
        public var unitIds: [String]
        public var tags: [String]

        public init(id: String, courseId: String, name: String, date: String, unitIds: [String] = [], tags: [String] = []) {
            self.id = id
            self.courseId = courseId
            self.name = name
            self.date = date
            self.unitIds = unitIds
            self.tags = tags
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            courseId = try c.decode(String.self, forKey: .courseId)
            name = try c.decode(String.self, forKey: .name)
            date = try c.decode(String.self, forKey: .date)
            unitIds = try c.decodeIfPresent([String].self, forKey: .unitIds) ?? []
            tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        }

        /// The parsed ``date``, or `nil` if it isn't in a supported format.
        public func parsedDate(in timeZone: TimeZone = .current) -> Date? {
            if let date = try? Date(date, strategy: .iso8601) {
                return date
            }
            let dayOnly = Date.ISO8601FormatStyle(timeZone: timeZone).year().month().day()
            return try? Date(date, strategy: dayOnly)
        }

        /// Formats a date the way ``date`` expects.
        public static func format(_ date: Date) -> String {
            date.formatted(.iso8601)
        }
    }
}

/// A decoding failure with the JSON path where it happened.
public struct ImportDecodingError: Error, CustomStringConvertible, Sendable {
    public let message: String

    public init(message: String) {
        self.message = message
    }

    init(_ error: DecodingError) {
        func path(_ codingPath: [any CodingKey]) -> String {
            let text = codingPath.map { key in key.intValue.map { "[\($0)]" } ?? ".\(key.stringValue)" }.joined()
            return text.isEmpty ? "(root)" : String(text.drop { $0 == "." })
        }
        switch error {
        case .keyNotFound(let key, let context):
            message = "\(path(context.codingPath + [key])): required field is missing."
        case .typeMismatch(let type, let context):
            message = "\(path(context.codingPath)): expected \(type). \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            message = "\(path(context.codingPath)): expected \(type) but found null."
        case .dataCorrupted(let context):
            message = "\(path(context.codingPath)): \(context.debugDescription)"
        @unknown default:
            message = error.localizedDescription
        }
    }

    public var description: String { message }
}
