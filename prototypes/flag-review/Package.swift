// swift-tools-version: 6.2
// PROTOTYPE — throwaway. Flag-review screen variants for issue #80. Run: swift run FlagReview [--variant A|B|C]
import PackageDescription

let package = Package(
    name: "FlagReview",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(name: "FlagReview", swiftSettings: [.swiftLanguageMode(.v5)])
    ]
)
