import MieracleKit

/// A decoded document waiting for the user to confirm.
struct PendingImport {
    let source: String
    let document: ImportDocument
    let plan: ImportPlan
}
