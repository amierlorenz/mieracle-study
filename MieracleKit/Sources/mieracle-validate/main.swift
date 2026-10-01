import Foundation
import MieracleKit

let paths = CommandLine.arguments.dropFirst()
guard !paths.isEmpty else {
    print("usage: mieracle-validate <file.json> [more.json ...]")
    exit(64)
}

var failed = false
var decoded: [(name: String, document: ImportDocument)] = []
for path in paths {
    let url = URL(filePath: path)
    do {
        let document = try ImportDocument.decode(from: Data(contentsOf: url))
        decoded.append((path, document))
        let issues = ImportValidator().validate(document)
        for issue in issues {
            print("\(path): \(issue)")
        }
        let concepts = document.courses.flatMap { $0.units.flatMap(\.concepts) }
        let prompts = concepts.reduce(0) { $0 + $1.prompts.count }
        let errors = issues.count { $0.severity == .error }
        print("\(path): \(errors == 0 ? "OK" : "FAILED") — \(document.courses.count) courses, \(concepts.count) concepts, \(prompts) prompts, \(document.exams.count) exams, \(errors) errors, \(issues.count - errors) warnings")
        failed = failed || errors > 0
    } catch let error as ImportDecodingError {
        print("\(path): error: \(error.message)")
        failed = true
    } catch {
        print("\(path): error: \(error.localizedDescription)")
        failed = true
    }
}
if decoded.count > 1 {
    let duplicates = ImportValidator.crossDocumentDuplicates(decoded)
    for issue in duplicates {
        print("\(issue.path): \(issue.severity.rawValue): \(issue.message)")
    }
    print("across \(decoded.count) files: \(duplicates.isEmpty ? "OK" : "FAILED") — \(duplicates.count) duplicate ids")
    failed = failed || !duplicates.isEmpty
}
exit(failed ? 1 : 0)
