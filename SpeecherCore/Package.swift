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
    dependencies: [
        .package(
            url: "https://github.com/argmaxinc/WhisperKit",
            from: "0.9.0"
        )
    ],
    targets: [
        .target(
            name: "SpeecherCore",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit")
            ],
            path: "Sources/SpeecherCore"
        ),
        .testTarget(
            name: "SpeecherCoreTests",
            dependencies: ["SpeecherCore"],
            path: "Tests/SpeecherCoreTests"
        )
    ]
)
