// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Looby",
    defaultLocalization: "fr",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "LoobyKit", targets: ["Looby"])
    ],
    targets: [
        .executableTarget(
            name: "Looby",
            path: "Sources",
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
