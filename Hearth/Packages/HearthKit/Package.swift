// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HearthKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "HearthKit",
            targets: ["HearthKit"]
        )
    ],
    targets: [
        .target(
            name: "HearthKit",
            path: "Sources/HearthKit"
        ),
        .testTarget(
            name: "HearthKitTests",
            dependencies: ["HearthKit"],
            path: "Tests/HearthKitTests"
        )
    ]
)
