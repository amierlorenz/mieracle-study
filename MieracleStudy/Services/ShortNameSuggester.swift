import MieracleKit

/// Suggests short class names with AI when available, otherwise by rule.
struct ShortNameSuggester {
    let provider: any AIProvider

    func suggestion(for name: String) async -> String {
        guard provider.isAvailable, let suggestion = try? await provider.suggestShortName(for: name) else {
            return ClassNameShortener.suggest(for: name)
        }
        return suggestion
    }
}
