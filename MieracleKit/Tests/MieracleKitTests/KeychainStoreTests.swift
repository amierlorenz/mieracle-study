import Foundation
import MieracleKit
import Testing

struct KeychainStoreTests {
    @Test func savesReadsAndDeletes() throws {
        let store = KeychainStore(service: "com.mieracle.MieracleStudy.tests.\(UUID().uuidString)", account: "token", isSynchronizable: false, usesDataProtectionKeychain: false)
        defer { try? store.delete() }

        #expect(try store.read() == nil)
        try store.save("fake-token-1")
        #expect(try store.read() == "fake-token-1")
        try store.save("fake-token-2")
        #expect(try store.read() == "fake-token-2")
        try store.delete()
        #expect(try store.read() == nil)
    }
}
