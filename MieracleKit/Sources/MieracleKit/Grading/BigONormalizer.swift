import Foundation

/// Compares Big-O answers by meaning rather than spelling.
///
/// `O(n log n)`, `nlogn`, and `O(N * lg(N))` are equal, as are `O(n²)` and
/// `O(n*n)`, or `O(V + E)` and `O(E+V)`. Constant coefficients are dropped.
/// Variables are single letters; `log`, `lg`, `ln`, `sqrt`, `√`, `^`, `!` are understood.
public enum BigONormalizer {
    /// A canonical form, or `nil` if the text can't be parsed.
    public static func normalize(_ text: String) -> String? {
        var body = text.lowercased().filter { !$0.isWhitespace }
        body = body.replacing("²", with: "^2").replacing("³", with: "^3").replacing("·", with: "*").replacing("×", with: "*")
        if body.hasPrefix("o("), body.hasSuffix(")") {
            body = String(body.dropFirst(2).dropLast())
        }
        guard !body.isEmpty, !containsWord(body) else { return nil }

        var terms: [String] = []
        for term in body.split(separator: "+", omittingEmptySubsequences: false) {
            guard let factors = parseTerm(Substring(term)) else { return nil }
            terms.append(factors)
        }
        return Set(terms).sorted().joined(separator: "+")
    }

    /// Whether two answers denote the same complexity.
    public static func areEquivalent(_ lhs: String, _ rhs: String) -> Bool {
        guard let a = normalize(lhs), let b = normalize(rhs) else { return false }
        return a == b
    }

    /// Words such as "linear" aren't products of variables.
    private static func containsWord(_ text: String) -> Bool {
        let withoutFunctions = text.replacing(/log|lg|ln|sqrt/, with: "_")
        return withoutFunctions.contains(/[a-z]{3,}/)
    }

    private static func parseTerm(_ term: Substring) -> String? {
        var scanner = Scanner(Array(term))
        var powers: [String: Int] = [:]
        var others: [String] = []

        while !scanner.isAtEnd {
            if scanner.consume("*") { continue }
            if scanner.consume("log") || scanner.consume("lg") || scanner.consume("ln") {
                guard let argument = scanner.argument() else { return nil }
                others.append("log(\(argument))")
            } else if scanner.consume("sqrt") || scanner.consume("√") {
                guard let argument = scanner.argument() else { return nil }
                others.append("sqrt(\(argument))")
            } else if let number = scanner.number() {
                if scanner.consume("^") {
                    guard let exponent = scanner.atom() else { return nil }
                    others.append("\(number)^\(exponent)")
                }
            } else if let letter = scanner.letter() {
                if scanner.consume("!") {
                    others.append("\(letter)!")
                } else if scanner.consume("^") {
                    if let exponent = scanner.number() {
                        powers[letter, default: 0] += Int(exponent) ?? 1
                    } else if let exponent = scanner.letter() {
                        others.append("\(letter)^\(exponent)")
                    } else {
                        return nil
                    }
                } else {
                    powers[letter, default: 0] += 1
                }
            } else {
                return nil
            }
        }

        let factors = powers.filter { $0.value > 0 }.map { $0.value == 1 ? $0.key : "\($0.key)^\($0.value)" } + others
        return factors.isEmpty ? "1" : factors.sorted().joined(separator: "*")
    }
}

private struct Scanner {
    private let characters: [Character]
    private var index = 0

    init(_ characters: [Character]) {
        self.characters = characters
    }

    var isAtEnd: Bool { index >= characters.count }

    mutating func consume(_ text: String) -> Bool {
        let target = Array(text)
        guard index + target.count <= characters.count, Array(characters[index..<index + target.count]) == target else { return false }
        index += target.count
        return true
    }

    mutating func number() -> String? {
        let start = index
        while !isAtEnd, characters[index].isNumber { index += 1 }
        return start == index ? nil : String(characters[start..<index])
    }

    mutating func letter() -> String? {
        guard !isAtEnd, characters[index].isLetter else { return nil }
        defer { index += 1 }
        return String(characters[index])
    }

    mutating func atom() -> String? {
        number() ?? letter()
    }

    /// A single-letter argument, optionally in parentheses: `n` or `(n)`.
    mutating func argument() -> String? {
        if consume("(") {
            guard let value = letter(), consume(")") else { return nil }
            return value
        }
        return letter()
    }
}
