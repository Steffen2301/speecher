// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SpeecherCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "SpeecherCore", targets: ["SpeecherCore"])
    ],
    targets: [
        .target(
            name: "SpeecherCore",
            path: "Sources/SpeecherCore"
        ),
        .testTarget(
            name: "SpeecherCoreTests",
            dependencies: ["SpeecherCore"],
            path: "Tests/SpeecherCoreTests"
        )
    ]
)
