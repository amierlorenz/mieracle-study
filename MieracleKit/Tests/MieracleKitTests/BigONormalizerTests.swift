import MieracleKit
import Testing

struct BigONormalizerTests {
    @Test(arguments: [
        ("O(n log n)", "nlogn"),
        ("O(n log n)", "O(N * lg(N))"),
        ("O(n log n)", "O(log n · n)"),
        ("O(n^2)", "O(n²)"),
        ("O(n^2)", "O(n*n)"),
        ("O(n^2)", "O(3n^2)"),
        ("O(V + E)", "O(e+v)"),
        ("O(1)", "o(1)"),
        ("O(1)", "O(5)"),
        ("O(log n)", "O(ln(n))"),
        ("O(2^n)", "O(2^N)"),
        ("O(n!)", "O(N!)"),
        ("O(sqrt(n))", "O(√n)"),
        ("O(m*n)", "O(nm)"),
        ("O(k log n)", "O(log(n) * k)"),
        ("O(n^3)", "O(n³)"),
    ])
    func equivalent(lhs: String, rhs: String) {
        #expect(BigONormalizer.areEquivalent(lhs, rhs))
    }

    @Test(arguments: [
        ("O(n log n)", "O(n)"),
        ("O(n^2)", "O(n)"),
        ("O(2^n)", "O(n^2)"),
        ("O(log n)", "O(n)"),
        ("O(m + n)", "O(m*n)"),
        ("O(1)", "O(n)"),
        ("O(n log k)", "O(n log n)"),
    ])
    func different(lhs: String, rhs: String) {
        #expect(!BigONormalizer.areEquivalent(lhs, rhs))
    }

    @Test(arguments: ["", "O()", "linear", "O(n log)", "O(n^)"])
    func rejectsUnparseable(text: String) {
        #expect(BigONormalizer.normalize(text) == nil)
    }
}
