import Foundation

/// Builds compact class names like "CSC 395 | Swift" from long registrar or
/// Canvas titles such as "Advanced Swift App Dev-ARKit - CSC-395-01-Fall 2026".
public enum ClassNameShortener {
    /// A rule-based suggestion: the course code (if any) and a one- or
    /// two-word topic.
    public static func suggest(for name: String) -> String {
        let code = courseCode(in: name)
        let topic = topic(in: name, removing: code)
        switch (code, topic.isEmpty) {
        case (let code?, false): return "\(code) | \(topic)"
        case (let code?, true): return code
        case (nil, _): return name.count <= 24 || topic.isEmpty ? name : topic
        }
    }

    /// A department code and number, such as "CSC 395".
    public static func courseCode(in name: String) -> String? {
        guard let match = name.firstMatch(of: /\b([A-Za-z]{2,4})[-\s]?(\d{3}[A-Za-z]?)\b/) else { return nil }
        return "\(match.1.uppercased()) \(match.2.uppercased())"
    }

    private static let stopWords: Set<String> = ["and", "&", "of", "the", "to", "for", "in", "a"]

    static func topic(in name: String, removing code: String?) -> String {
        var title = name
        if let range = name.firstRange(of: /\b[A-Za-z]{2,4}[-\s]?\d{3}[A-Za-z]?\b.*$/) {
            title = String(name[..<range.lowerBound])
        }
        title = title.split(whereSeparator: { "-–—/(:|".contains($0) }).first.map(String.init) ?? title
        title = title.trimmingCharacters(in: .whitespaces)
        var lowered = title.lowercased()
        while let match = lowered.firstMatch(of: /^(introduction to|intro to|advanced|principles of|fundamentals of|foundations of|topics in|survey of)\s+/) {
            title = String(title.dropFirst(match.output.0.count))
            lowered = title.lowercased()
        }
        let words = title.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        let meaningful = words.filter { !stopWords.contains($0.lowercased()) && $0.wholeMatch(of: /[IVX]+/) == nil }
        return meaningful.prefix(2).joined(separator: " ")
    }
}
