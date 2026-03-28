// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Privlens",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "PrivlensCore", targets: ["PrivlensCore"]),
        .library(name: "PrivlensUI", targets: ["PrivlensUI"]),
    ],
    targets: [
        .target(
            name: "PrivlensCore",
            dependencies: [],
            path: "Sources/PrivlensCore"
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
