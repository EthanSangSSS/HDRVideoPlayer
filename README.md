# HDRVideoPlayer

Windows-first HDR / Dolby Vision local video player lab with an experimental parallel macOS-native track and an evidence-first HDR diagnostics model.

## Status

Validated Windows scaffold + Media Foundation metadata diagnostics + experimental Windows system-media preview. The experimental macOS Swift Package adds AVFoundation diagnostics, AVPlayer system preview, NSScreen EDR facts, a completed bounded local system-open matrix, and an isolated static Metal EDR test pattern without claiming platform parity or presentation accuracy.

This repository intentionally starts with:
- a WinUI 3 shell;
- a Media Foundation metadata probe with a bounded extension fallback;
- HDR / Dolby Vision domain models;
- validation docs;
- legal / codec boundaries;
- CI and bootstrap scripts.

It does **not** yet claim correct HDR10, HLG, or Dolby Vision playback.

The macOS scaffold is a separate early track. Its Metal executable renders fixed FP16 test pixels only. Display support comes from potential EDR capability, while current headroom remains a separate fact. GPU completion and readback do not add a VideoToolbox frame path or prove HDR or Dolby Vision video presentation accuracy.

## Why this exists

Many local players can render HDR-looking video, but they often hide the actual pipeline:
- Was the file decoded as 8-bit or 10-bit?
- Is it PQ, HLG, SDR, or Dolby Vision?
- Which Dolby Vision profile was detected?
- Is playback going through system media, a custom D3D11 path, or SDR fallback?
- Is dynamic metadata applied, ignored, or impossible?
- Is the display actually in an HDR-capable mode?

HDRVideoPlayer is designed as a local player + diagnostics workbench.

## Design influence

The project is inspired by HDRImageViewer's strong architectural ideas:
- WinUI 3 app shell;
- `SwapChainPanel`-style rendering;
- Direct3D 11 HDR presentation;
- FP16 scRGB renderer thinking;
- metadata-first diagnostics;
- explicit format support matrix.

This repository starts clean-room. Do not copy code from HDRImageViewer unless GPLv3-or-later obligations are preserved.

## Planned stack

| Layer | Initial target |
|---|---|
| UI | WinUI 3 / Windows App SDK |
| Core model | C# domain models |
| Probe v0 | metadata stub + extension heuristics |
| Probe v1 | Media Foundation / container metadata |
| Probe lab path | optional FFmpeg metadata probe, user-provided binary only |
| Renderer v0 | system media preview |
| Renderer v1 | D3D11 FP16 scRGB test-pattern renderer |
| Renderer v2 | P010/NV12 video frame path |
| Dolby Vision | detection first, Profile 8.1 HDR10-compatible fallback later |

## Experimental macOS track

The macOS scaffold lives under `macos/HDRVideoPlayerMac` as a Swift Package targeting macOS 13 or later:

- AppKit executable shell and local file picker;
- AVKit / AVPlayer system-media preview;
- AVFoundation / CoreMedia metadata diagnostics;
- separate NSScreen EDR support, current headroom, potential, and reference facts;
- isolated `rgba16Float` Metal EDR static test pattern with unified/managed GPU readback checks;
- asynchronous interactive command-buffer completion and failure state;
- Swift-native core models and pure model tests.

AVPlayer readiness is only a system-path state. Static Metal values above `1.0` prove only submitted pixels. Presentation remains unknown and unverified, and no HDR or Dolby Vision video rendering accuracy is claimed.

## Current scaffold capabilities

- Opens as a WinUI 3 application shell.
- Provides a placeholder file-open flow.
- Builds a `MediaAsset` model from the selected file path.
- Classifies likely container type from extension.
- Reads available codec, dimensions, frame rate, audio, color, and luminance attributes through Media Foundation on Windows.
- Reports low-confidence Dolby Vision filename-marker candidates without claiming parsed Dolby Vision metadata.
- Shows explicitly bounded HDR / Dolby Vision status.
- Provides a manual Windows system-media preview with explicit loading, ready, and failed states.
- Keeps metadata facts, system playback state, and presentation claims separate.
- Separates system playback, custom renderer, and unsupported states.

Probe v1 remains diagnostics-only. System playback success does not establish HDR or Dolby Vision presentation accuracy; presentation remains unknown until independently measured.

## Non-goals

- No DRM bypass.
- No proprietary Dolby SDK redistribution.
- No unlicensed sample media.
- No claim of Dolby Vision certification.
- No claim of full Dolby Vision Profile 5 / 7 support.
- No bundled FFmpeg, mpv, libplacebo, codec packs, or HEVC binaries in early public milestones.

## Build

Windows + Visual Studio 2022 recommended.

```powershell
dotnet restore .\src\HDRVideoPlayer.App\HDRVideoPlayer.App.csproj
dotnet build .\src\HDRVideoPlayer.App\HDRVideoPlayer.App.csproj -c Debug
dotnet test .\tests\HDRVideoPlayer.Core.Tests\HDRVideoPlayer.Core.Tests.csproj -c Debug
```

macOS 13 or later with Xcode command-line tools:

```bash
swift build --package-path macos/HDRVideoPlayerMac -Xswiftc -warnings-as-errors
swift test --package-path macos/HDRVideoPlayerMac -Xswiftc -warnings-as-errors
swift build --package-path macos/HDRVideoPlayerMac --configuration release -Xswiftc -warnings-as-errors
swift run --package-path macos/HDRVideoPlayerMac HDRVideoPlayerMac
swift run --package-path macos/HDRVideoPlayerMac HDRVideoPlayerMacEDRPattern
# Requires a repository-external manifest with authorized local media:
swift run --package-path macos/HDRVideoPlayerMac HDRVideoPlayerMacLocalValidation \
  --manifest /absolute/path/macos-local-validation-fixtures.json
```

## Repo creation

If this is not yet in GitHub:

```powershell
.\scripts\create-public-repo.ps1 -Owner EthanSangSSS -Repo HDRVideoPlayer
```

## Read next

- `docs/PRD.md`
- `docs/ARCHITECTURE.md`
- `docs/DOLBY_VISION_STRATEGY.md`
- `docs/LEGAL_AND_CODEC_BOUNDARY.md`
- `docs/VALIDATION_MATRIX.md`
- `docs/SYSTEM_PLAYBACK_VALIDATION.md`
- `docs/MACOS_FEASIBILITY.md`
- `docs/MACOS_ARCHITECTURE.md`
- `docs/MACOS_VALIDATION_MATRIX.md`
- `docs/MACOS_LOCAL_VALIDATION.md`
- `docs/MACOS_EDR_TEST_PATTERN.md`
- `docs/ROADMAP.md`
- `AGENTS.md`
