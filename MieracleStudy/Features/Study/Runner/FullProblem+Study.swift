import MieracleKit

extension PromptContent.FullProblem {
    /// Everything shown once all stages are done.
    var revealMarkdown: String {
        var parts = ["**Pattern:** \(pattern)", "**Plan**\n\n\(plan)"]
        if let referenceSolution {
            parts.append("**Reference solution**\n\n```\(language.rawValue)\n\(referenceSolution)\n```")
        }
        parts.append("**Time** \(time) · **Space** \(space)")
        if !explanation.isEmpty {
            parts.append(explanation)
        }
        return parts.joined(separator: "\n\n")
    }
}
