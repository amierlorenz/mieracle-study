import Foundation
import MieracleKit
import Testing

struct SchemaFileTests {
    @Test func schemaListsEveryPromptKind() throws {
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "../../../Schema/import-v1.schema.json")
            .standardizedFileURL
        let schema = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let defs = try #require(schema["$defs"] as? [String: Any])
        let prompt = try #require(defs["prompt"] as? [String: Any])
        let variants = try #require(prompt["oneOf"] as? [[String: Any]])
        let kinds = variants.compactMap { (($0["properties"] as? [String: Any])?["type"] as? [String: Any])?["const"] as? String }

        #expect(Set(kinds) == Set(PromptKind.allCases.map(\.rawValue)))
        #expect((schema["properties"] as? [String: Any]).flatMap { ($0["schemaVersion"] as? [String: Any])?["const"] as? Int } == MieracleKit.schemaVersion)
    }
}
