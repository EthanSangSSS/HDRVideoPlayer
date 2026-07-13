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
        .testTarget(
            name: "HDRVideoPlayerMacCoreTests",
            dependencies: ["HDRVideoPlayerMacCore"]
        )
    ]
)
