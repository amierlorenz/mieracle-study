import Foundation
import MieracleKit
import SwiftData
import Testing

@MainActor
struct DataResetTests {
    @Test func deletesEverything() throws {
        let container = try ModelContainerFactory.make(storage: .inMemory)
        let context = container.mainContext
        try Importer(context: context).apply(ImportDocument.decode(from: ImportDocumentTests.fixture()))
        context.insert(SessionPreset(name: "P", configData: Data()))
        try context.save()

        try DataReset.deleteAll(in: context)

        #expect(try context.fetchCount(FetchDescriptor<Course>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Prompt>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Exam>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ConceptTag>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SessionPreset>()) == 0)
    }
}
