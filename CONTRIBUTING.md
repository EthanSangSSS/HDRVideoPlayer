# Contributing

Thank you for improving `HDRVideoPlayer`.

This repository is an evidence-first HDR / Dolby Vision diagnostics lab. Contributions should preserve the distinction between metadata detection, system playback state, renderer behavior, and verified presentation accuracy.

## Contribution priorities

High-value contributions include:

1. clearer validation matrices;
2. public-safe metadata fixtures;
3. build and test reliability improvements;
4. renderer and probe code with explicit evidence boundaries;
5. documentation that avoids unsupported HDR / Dolby Vision claims.

## Required boundaries

Do not include:

- copyrighted sample media;
- proprietary Dolby SDKs, codec packs, HEVC binaries, FFmpeg binaries, or mpv/libplacebo binaries unless licensing is explicitly handled;
- DRM bypass instructions;
- private local media paths, logs, or device identifiers;
- claims of Dolby Vision certification or HDR presentation accuracy without validation evidence.

## Pull request process

1. Keep the scope narrow.
2. Identify changed surface: Windows app, macOS scaffold, core model, probe, renderer, docs, scripts, tests, or CI.
3. State what was actually validated.
4. Separate metadata facts, system playback state, and presentation claims.
5. Do not mark a result as `PASS` unless exact command output or measurement evidence exists.

## Suggested validation

Windows:

```powershell
dotnet restore .\src\HDRVideoPlayer.App\HDRVideoPlayer.App.csproj
dotnet build .\src\HDRVideoPlayer.App\HDRVideoPlayer.App.csproj -c Debug
dotnet test .\tests\HDRVideoPlayer.Core.Tests\HDRVideoPlayer.Core.Tests.csproj -c Debug
```

macOS:

```bash
swift build --package-path macos/HDRVideoPlayerMac
swift test --package-path macos/HDRVideoPlayerMac
```

If a command cannot run in the current environment, state that limitation instead of claiming success.
