import MieracleKit
import Testing

struct StarterCodeTests {
    @Test(arguments: [
        ("import heapq\n\ndef k_largest(nums, k):\n    pass\n", "def k_largest(nums, k):\n    pass\n"),
        ("from collections import deque\nimport math\ndef f():\n    pass", "def f():\n    pass"),
        ("import Foundation\n\nfunc twoSum(_ nums: [Int]) -> [Int] {\n    []\n}", "func twoSum(_ nums: [Int]) -> [Int] {\n    []\n}"),
        ("def important():\n    pass", "def important():\n    pass"),
    ])
    func stripsImports(code: String, expected: String) {
        #expect(StarterCode.withoutImports(code) == expected)
    }
}
