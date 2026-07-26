# PROJECT_COMMAND_CENTER — HDRVideoPlayer

## Purpose

Public portfolio project for a Windows-first HDR / Dolby Vision local player and diagnostics workbench, with an experimental parallel macOS-native track.

## Current phase

Validated Windows scaffold with Media Foundation metadata diagnostics and an experimental Windows system-media preview. The parallel macOS track uses AVFoundation, AVKit, AppKit, NSScreen diagnostics, and an isolated static Metal EDR test pattern.

## Product boundary

This is not a certified Dolby Vision product. It does not bypass DRM. It does not bundle patent-encumbered codec binaries or commercial sample videos. It starts by detecting and explaining playback paths before claiming rendering accuracy.

## Canonical docs

- `README.md`
- `docs/PRD.md`
- `docs/ARCHITECTURE.md`
- `docs/DOLBY_VISION_STRATEGY.md`
- `docs/LEGAL_AND_CODEC_BOUNDARY.md`
- `docs/VALIDATION_MATRIX.md`
- `docs/MACOS_FEASIBILITY.md`
- `docs/MACOS_ARCHITECTURE.md`
- `docs/MACOS_VALIDATION_MATRIX.md`
- `docs/MACOS_LOCAL_VALIDATION.md`
- `docs/ROADMAP.md`
- `docs/HDRIMAGEVIEWER_INFLUENCE.md`
- `AGENTS.md`

## Current validation gate

`chore/system-playback-validation` provides the local-only protocol and record generator. Run it on Windows with locally licensed, uncommitted codec/container fixtures before selecting the next playback feature.

Required evidence:

- metadata facts recorded separately from inferred facts and unknowns;
- Windows system-media result recorded as `Ready` or `Failed`;
- visible presentation observation recorded separately;
- presentation claim retained as unknown and unverified.

Boundaries:

- No codec binaries.
- No sample media.
- No Dolby rendering claim.

Validation:

- `dotnet restore .\src\HDRVideoPlayer.App\HDRVideoPlayer.App.csproj`
- `dotnet build .\src\HDRVideoPlayer.App\HDRVideoPlayer.App.csproj -c Debug`
- `dotnet test .\tests\HDRVideoPlayer.Core.Tests\HDRVideoPlayer.Core.Tests.csproj -c Debug`
- `.\scripts\public-safety-scan.ps1`
- `git diff --check`

## Parallel macOS track

Current scope:

- Swift Package under `macos/HDRVideoPlayerMac` targeting macOS 13 or later.
- AppKit + AVPlayerView system-media preview.
- AVFoundation/CoreMedia metadata facts.
- NSScreen EDR capability facts.
- Static `rgba16Float` Metal EDR test pixels with GPU readback validation.
- Unknown and unverified presentation claim.

Current macOS PR:

`feat/macos-edr-test-pattern`

The repository-external six-category system-preview record completed without timeouts, and the sanitized result is in `docs/MACOS_VALIDATION_MATRIX.md`. This milestone adds a static Metal EDR test pattern only. It does not accept decoded video frames, add VideoToolbox, or promote HDR or Dolby Vision presentation claims.

Next macOS gate:

Validate the static pattern on an EDR-capable display using `docs/MACOS_EDR_TEST_PATTERN.md`. Do not begin a VideoToolbox/CVPixelBuffer frame path until that observation is reviewed.

macOS validation:

- `swift build --package-path macos/HDRVideoPlayerMac`
- `swift test --package-path macos/HDRVideoPlayerMac`
- `swift run --package-path macos/HDRVideoPlayerMac HDRVideoPlayerMacEDRPattern`
- `swift run --package-path macos/HDRVideoPlayerMac HDRVideoPlayerMacLocalValidation --manifest /absolute/path/outside-the-repo.json`
- `git diff --check`
