// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HDRVideoPlayerMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "HDRVideoPlayerMacCore",
            targets: ["HDRVideoPlayerMacCore"]
        ),
        .executable(
            name: "HDRVideoPlayerMac",
            targets: ["HDRVideoPlayerMac"]
        ),
        .executable(
            name: "HDRVideoPlayerMacLocalValidation",
            targets: ["HDRVideoPlayerMacLocalValidation"]
        ),
        .executable(
            name: "HDRVideoPlayerMacEDRPattern",
            targets: ["HDRVideoPlayerMacEDRPattern"]
        )
    ],
    targets: [
        .target(
            name: "HDRVideoPlayerMacCore"
        ),
        .executableTarget(
            name: "HDRVideoPlayerMac",
            dependencies: ["HDRVideoPlayerMacCore"]
        ),
        .executableTarget(
            name: "HDRVideoPlayerMacLocalValidation",
            dependencies: ["HDRVideoPlayerMacCore"]
        ),
        .target(
            name: "HDRVideoPlayerMacMetal",
            dependencies: ["HDRVideoPlayerMacCore"]
        ),
        .executableTarget(
            name: "HDRVideoPlayerMacEDRPattern",
            dependencies: ["HDRVideoPlayerMacCore", "HDRVideoPlayerMacMetal"]
        ),
        .testTarget(
            name: "HDRVideoPlayerMacCoreTests",
            dependencies: ["HDRVideoPlayerMacCore"]
        ),
        .testTarget(
            name: "HDRVideoPlayerMacMetalTests",
            dependencies: ["HDRVideoPlayerMacCore", "HDRVideoPlayerMacMetal"]
        )
    ]
)
