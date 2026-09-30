import Foundation

/// The kinds of prompt a concept can have.
public enum PromptKind: String, Codable, CaseIterable, Sendable {
    case flashcard
    case shortAnswer
    case multipleChoice
    case codeImplement
    case codeComplexity
    case patternPick

    /// Whether the kind needs a code runner, which only exists on macOS.
    public var requiresCodeRunner: Bool { self == .codeImplement }

    public var displayName: String {
        switch self {
        case .flashcard: "Flashcard"
        case .shortAnswer: "Short answer"
        case .multipleChoice: "Multiple choice"
        case .codeImplement: "Code: implement"
        case .codeComplexity: "Code: complexity"
        case .patternPick: "Code: pattern pick"
        }
    }
}

/// The payload of a prompt.
///
/// Encodes as a flat JSON object with a `type` discriminator, which is the same
/// shape the import format uses:
///
/// ```json
/// { "type": "flashcard", "front": "…", "back": "…" }
/// ```
public enum PromptContent: Hashable, Sendable {
    case flashcard(Flashcard)
    case shortAnswer(ShortAnswer)
    case multipleChoice(MultipleChoice)
    case codeImplement(CodeImplement)
    case codeComplexity(CodeComplexity)
    case patternPick(PatternPick)

    public var kind: PromptKind {
        switch self {
        case .flashcard: .flashcard
        case .shortAnswer: .shortAnswer
        case .multipleChoice: .multipleChoice
        case .codeImplement: .codeImplement
        case .codeComplexity: .codeComplexity
        case .patternPick: .patternPick
        }
    }

    /// The text shown before the learner answers.
    public var questionText: String {
        switch self {
        case .flashcard(let c): c.front
        case .shortAnswer(let c): c.question
        case .multipleChoice(let c): c.question
        case .codeImplement(let c): c.statement
        case .codeComplexity(let c): c.code
        case .patternPick(let c): c.statement
        }
    }
}

extension PromptContent: Codable {
    private enum TypeKey: String, CodingKey {
        case type
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: TypeKey.self)
        let kind = try container.decode(PromptKind.self, forKey: .type)
        switch kind {
        case .flashcard: self = .flashcard(try Flashcard(from: decoder))
        case .shortAnswer: self = .shortAnswer(try ShortAnswer(from: decoder))
        case .multipleChoice: self = .multipleChoice(try MultipleChoice(from: decoder))
        case .codeImplement: self = .codeImplement(try CodeImplement(from: decoder))
        case .codeComplexity: self = .codeComplexity(try CodeComplexity(from: decoder))
        case .patternPick: self = .patternPick(try PatternPick(from: decoder))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: TypeKey.self)
        try container.encode(kind, forKey: .type)
        switch self {
        case .flashcard(let c): try c.encode(to: encoder)
        case .shortAnswer(let c): try c.encode(to: encoder)
        case .multipleChoice(let c): try c.encode(to: encoder)
        case .codeImplement(let c): try c.encode(to: encoder)
        case .codeComplexity(let c): try c.encode(to: encoder)
        case .patternPick(let c): try c.encode(to: encoder)
        }
    }
}

extension PromptContent {
    public struct Flashcard: Codable, Hashable, Sendable {
        public var front: String
        public var back: String

        public init(front: String, back: String) {
            self.front = front
            self.back = back
        }
    }

    public struct ShortAnswer: Codable, Hashable, Sendable {
        public var question: String
        public var modelAnswer: String
        /// Points a correct answer must mention; used for AI grading.
        public var keyPoints: [String]

        public init(question: String, modelAnswer: String, keyPoints: [String] = []) {
            self.question = question
            self.modelAnswer = modelAnswer
            self.keyPoints = keyPoints
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            question = try c.decode(String.self, forKey: .question)
            modelAnswer = try c.decode(String.self, forKey: .modelAnswer)
            keyPoints = try c.decodeIfPresent([String].self, forKey: .keyPoints) ?? []
        }
    }

    public struct MultipleChoice: Codable, Hashable, Sendable {
        public var question: String
        public var options: [String]
        public var correctIndex: Int
        public var explanation: String?

        public init(question: String, options: [String], correctIndex: Int, explanation: String? = nil) {
            self.question = question
            self.options = options
            self.correctIndex = correctIndex
            self.explanation = explanation
        }
    }

    /// Write a function that passes the given test cases.
    public struct CodeImplement: Codable, Hashable, Sendable {
        public var statement: String
        public var language: CodeLanguage
        public var functionName: String
        public var starterCode: String
        public var tests: [CodeTestCase]
        public var comparison: OutputComparison
        public var referenceSolution: String?
        public var explanation: String?

        public init(
            statement: String,
            language: CodeLanguage = .python,
            functionName: String,
            starterCode: String,
            tests: [CodeTestCase],
            comparison: OutputComparison = .exact,
            referenceSolution: String? = nil,
            explanation: String? = nil
        ) {
            self.statement = statement
            self.language = language
            self.functionName = functionName
            self.starterCode = starterCode
            self.tests = tests
            self.comparison = comparison
            self.referenceSolution = referenceSolution
            self.explanation = explanation
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            statement = try c.decode(String.self, forKey: .statement)
            language = try c.decodeIfPresent(CodeLanguage.self, forKey: .language) ?? .python
            functionName = try c.decode(String.self, forKey: .functionName)
            starterCode = try c.decodeIfPresent(String.self, forKey: .starterCode) ?? ""
            tests = try c.decode([CodeTestCase].self, forKey: .tests)
            comparison = try c.decodeIfPresent(OutputComparison.self, forKey: .comparison) ?? .exact
            referenceSolution = try c.decodeIfPresent(String.self, forKey: .referenceSolution)
            explanation = try c.decodeIfPresent(String.self, forKey: .explanation)
        }
    }

    /// State the time and space complexity of a snippet.
    public struct CodeComplexity: Codable, Hashable, Sendable {
        public var code: String
        public var language: CodeLanguage
        public var time: String
        public var space: String
        public var explanation: String

        public init(code: String, language: CodeLanguage = .python, time: String, space: String, explanation: String) {
            self.code = code
            self.language = language
            self.time = time
            self.space = space
            self.explanation = explanation
        }

        public init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            code = try c.decode(String.self, forKey: .code)
            language = try c.decodeIfPresent(CodeLanguage.self, forKey: .language) ?? .python
            time = try c.decode(String.self, forKey: .time)
            space = try c.decode(String.self, forKey: .space)
            explanation = try c.decode(String.self, forKey: .explanation)
        }
    }

    /// Choose the approach or data structure for a problem, without coding it.
    ///
    /// With `options` it is graded as multiple choice; without, the free-text
    /// answer is compared to `answer`.
    public struct PatternPick: Codable, Hashable, Sendable {
        public var statement: String
        public var options: [String]?
        public var correctIndex: Int?
        public var answer: String
        public var explanation: String

        public init(statement: String, options: [String]? = nil, correctIndex: Int? = nil, answer: String, explanation: String) {
            self.statement = statement
            self.options = options
            self.correctIndex = correctIndex
            self.answer = answer
            self.explanation = explanation
        }
    }
}

public enum CodeLanguage: String, Codable, CaseIterable, Sendable {
    case python
    case swift
}

/// How a function's return value is compared with the expected value.
public enum OutputComparison: String, Codable, CaseIterable, Sendable {
    case exact
    /// Lists compared ignoring order.
    case unordered
    /// Numbers compared with a small tolerance.
    case float
}

/// One call to the function under test.
public struct CodeTestCase: Codable, Hashable, Sendable {
    public var args: [JSONValue]
    public var expected: JSONValue
    /// Hidden tests count toward the result but their inputs aren't shown.
    public var isHidden: Bool

    public init(args: [JSONValue], expected: JSONValue, isHidden: Bool = false) {
        self.args = args
        self.expected = expected
        self.isHidden = isHidden
    }

    private enum CodingKeys: String, CodingKey {
        case args, expected, isHidden = "hidden"
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        args = try c.decode([JSONValue].self, forKey: .args)
        expected = try c.decode(JSONValue.self, forKey: .expected)
        isHidden = try c.decodeIfPresent(Bool.self, forKey: .isHidden) ?? false
    }
}
