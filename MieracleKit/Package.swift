// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "MieracleKit",
    platforms: [.macOS(.v27), .iOS(.v27)],
    products: [
        .library(name: "MieracleKit", targets: ["MieracleKit"]),
        .executable(name: "mieracle-validate", targets: ["mieracle-validate"]),
    ],
    targets: [
        .target(name: "MieracleKit", resources: [.copy("Rendering/Web")]),
        .executableTarget(name: "mieracle-validate", dependencies: ["MieracleKit"]),
        .testTarget(name: "MieracleKitTests", dependencies: ["MieracleKit"], resources: [.copy("Fixtures")])
    ]
)
