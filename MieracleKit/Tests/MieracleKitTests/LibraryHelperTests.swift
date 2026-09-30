import Foundation
import MieracleKit
import SwiftData
import Testing

@MainActor
struct LibraryHelperTests {
    let container: ModelContainer

    init() throws {
        container = try ModelContainerFactory.make(storage: .inMemory)
    }

    @Test func resolveReusesAndCreatesTags() throws {
        let context = container.mainContext
        context.insert(ConceptTag(name: "exam2"))
        try context.save()

        let tags = try ConceptTag.resolve(names: [" exam2", "recursion", "", "recursion"], in: context)

        #expect(tags.map(\.name) == ["exam2", "recursion"])
        #expect(try context.fetchCount(FetchDescriptor<ConceptTag>()) == 2)
    }

    @Test func parsesResourceLines() {
        let text = """
        Visualgo | https://visualgo.net/en/heap
        https://docs.python.org/3/library/heapq.html
        not a link
        Bad | ftp://example.com
        """
        let resources = Resource.parse(lines: text)
        #expect(resources.map(\.title) == ["Visualgo", "docs.python.org"])
        #expect(Resource.parse(lines: Resource.format(lines: resources)) == resources)
    }
}
