import Foundation

extension JSONValue {
    /// Whether an actual result matches this expected value under a comparison mode.
    public func matches(_ actual: JSONValue, comparison: OutputComparison) -> Bool {
        switch (comparison, self, actual) {
        case (.float, .number(let expected), .number(let value)):
            return abs(expected - value) <= max(1e-6, 1e-6 * abs(expected))
        case (.float, .array(let expected), .array(let values)):
            return expected.count == values.count && zip(expected, values).allSatisfy { $0.matches($1, comparison: .float) }
        case (.unordered, .array(let expected), .array(let values)):
            return expected.map(\.sortKey).sorted() == values.map(\.sortKey).sorted()
        default:
            return self == actual
        }
    }

    private var sortKey: String {
        (try? JSONEncoder().encode(self)).map { String(decoding: $0, as: UTF8.self) } ?? ""
    }
}
