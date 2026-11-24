// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LoobyTaker",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "LoobyTaker",
            targets: ["LoobyTaker"]
        )
    ],
    targets: [
        .target(
            name: "LoobyTaker",
            path: "Sources"
        )
    ]
)
