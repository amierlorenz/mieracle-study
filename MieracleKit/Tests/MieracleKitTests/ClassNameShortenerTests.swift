import MieracleKit
import Testing

struct ClassNameShortenerTests {
    @Test(arguments: [
        ("Advanced Swift App Dev-ARKit - CSC-395-01-Fall 2026", "CSC 395 | Swift App"),
        ("Intro to Info Assurance - CSC-382-01-Fall 2026", "CSC 382 | Info Assurance"),
        ("Intro to Phys  I/Calculus - PHY-203-04-Fall 2026", "PHY 203 | Phys"),
        ("Operating Systems I - CSC-301-01-Fall 2026", "CSC 301 | Operating Systems"),
        ("Probability & Stats - MAT-305-01-Fall 2026", "MAT 305 | Probability Stats"),
        ("Make It Stick", "Make It Stick"),
        ("Introduction to Cognitive Psychology and Learning", "Cognitive Psychology"),
        ("Discrete", "Discrete"),
    ])
    func suggests(name: String, expected: String) {
        #expect(ClassNameShortener.suggest(for: name) == expected)
    }

    @Test func findsCourseCodes() {
        #expect(ClassNameShortener.courseCode(in: "csc395 Swift") == "CSC 395")
        #expect(ClassNameShortener.courseCode(in: "Make It Stick") == nil)
    }
}
