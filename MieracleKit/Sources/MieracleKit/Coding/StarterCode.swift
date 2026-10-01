/// Prepares starter code for the editor.
public enum StarterCode {
    /// Removes import lines: which module to import is part of the answer,
    /// and showing it gives the approach away (`import heapq`).
    public static func withoutImports(_ code: String) -> String {
        let lines = code.split(separator: "\n", omittingEmptySubsequences: false)
        let kept = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !(trimmed.hasPrefix("import ") || trimmed.wholeMatch(of: /from\s+\S+\s+import\s+.+/) != nil)
        }
        return String(kept.joined(separator: "\n").drop { $0 == "\n" })
    }
}
