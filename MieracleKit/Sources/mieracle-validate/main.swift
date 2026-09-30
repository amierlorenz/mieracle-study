import Foundation
import MieracleKit

let paths = CommandLine.arguments.dropFirst()
guard !paths.isEmpty else {
    print("usage: mieracle-validate <file.json> [more.json ...]")
    exit(64)
}

var failed = false
for path in paths {
    let url = URL(filePath: path)
    do {
        let document = try ImportDocument.decode(from: Data(contentsOf: url))
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
exit(failed ? 1 : 0)
