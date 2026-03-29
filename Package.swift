// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Privlens",
    platforms: [.iOS("26.0"), .macOS(.v15)],
    products: [
        .library(name: "PrivlensCore", targets: ["PrivlensCore"]),
        .library(name: "PrivlensUI", targets: ["PrivlensUI"]),
    ],
    targets: [
        .target(
            name: "PrivlensCore",
            dependencies: [],
            path: "Sources/PrivlensCore",
            swiftSettings: [
                .define("ENABLE_FOUNDATION_MODELS", .when(platforms: [.iOS, .macOS]))
            ]
        ),
        .target(
            name: "PrivlensUI",
            dependencies: ["PrivlensCore"],
            path: "Sources/PrivlensUI"
        ),
        .testTarget(
            name: "PrivlensCoreTests",
            dependencies: ["PrivlensCore"],
            path: "Tests/PrivlensCoreTests"
        ),
    ]
)
