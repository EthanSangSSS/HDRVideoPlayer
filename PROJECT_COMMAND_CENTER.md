# PROJECT_COMMAND_CENTER — HDRVideoPlayer

## Purpose

Public portfolio project for a Windows-first HDR / Dolby Vision local player and diagnostics workbench.

## Current phase

Scaffold / Milestone 0.

## Product boundary

This is not a certified Dolby Vision product. It does not bypass DRM. It does not bundle patent-encumbered codec binaries or commercial sample videos. It starts by detecting and explaining playback paths before claiming rendering accuracy.

## Canonical docs

- `README.md`
- `docs/PRD.md`
- `docs/ARCHITECTURE.md`
- `docs/DOLBY_VISION_STRATEGY.md`
- `docs/LEGAL_AND_CODEC_BOUNDARY.md`
- `docs/VALIDATION_MATRIX.md`
- `docs/ROADMAP.md`
- `docs/HDRIMAGEVIEWER_INFLUENCE.md`
- `AGENTS.md`

## Next PR

`chore/winui-shell-validation`

Scope:

- Verify WinUI scaffold builds.
- Fix template issues.
- Keep metadata probe as bounded stub.
- No codec binaries.
- No sample media.
- No Dolby rendering claim.

Validation:

- `dotnet restore .\src\HDRVideoPlayer.App\HDRVideoPlayer.App.csproj`
- `dotnet build .\src\HDRVideoPlayer.App\HDRVideoPlayer.App.csproj -c Debug`
- `dotnet test .\tests\HDRVideoPlayer.Core.Tests\HDRVideoPlayer.Core.Tests.csproj -c Debug`
- `.\scripts\public-safety-scan.ps1`
- `git diff --check`
