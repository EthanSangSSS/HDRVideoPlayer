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
        .testTarget(
            name: "HDRVideoPlayerMacCoreTests",
            dependencies: ["HDRVideoPlayerMacCore"]
        )
    ]
)
