// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReceiptsOrganizer",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .executable(
            name: "ReceiptsOrganizer",
            targets: ["ReceiptsOrganizer"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ReceiptsOrganizer",
            path: "Sources/ReceiptsOrganizer",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ReceiptsOrganizerTests",
            dependencies: ["ReceiptsOrganizer"],
            path: "Tests/ReceiptsOrganizerTests"
        )
    ]
)
