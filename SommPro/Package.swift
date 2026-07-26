// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SommPro",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .executable(
            name: "SommPro",
            targets: ["SommPro"]
        )
    ],
    targets: [
        .executableTarget(
            name: "SommPro",
            path: "Sources/SommPro",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SommProTests",
            dependencies: ["SommPro"],
            path: "Tests/SommProTests"
        )
    ]
)
