// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "MieracleKit",
    platforms: [.macOS(.v27), .iOS(.v27)],
    products: [
        .library(name: "MieracleKit", targets: ["MieracleKit"])
    ],
    targets: [
        .target(name: "MieracleKit"),
        .testTarget(name: "MieracleKitTests", dependencies: ["MieracleKit"])
    ]
)
