# Agent Handoff Guide

## Mission

Build HDRVideoPlayer into a Windows-first HDR / Dolby Vision local video player and diagnostics workbench.

## Ground rules

- Do not claim Dolby Vision certification.
- Do not add DRM circumvention.
- Do not bundle proprietary Dolby SDKs.
- Do not bundle FFmpeg, mpv, libplacebo, x265, HEVC codec packs, or sample videos before license review.
- Do not copy code from HDRImageViewer unless GPLv3-or-later obligations are preserved.
- Treat HDR10, HLG, Dolby Vision Profile 5, Profile 7, and Profile 8.1 as separate capabilities.
- Every playback claim must state evidence, sample type, display path, renderer path, and limitation.

## Current repo state

This is a scaffold, not a finished player.

Expected initial projects:

- `src/HDRVideoPlayer.App`
- `src/HDRVideoPlayer.Core`
- `tests/HDRVideoPlayer.Core.Tests`

## First implementation PR sequence

1. `chore/winui-shell-validation`: ensure scaffold builds on Windows; fix project template issues; no playback claims.
2. `feat/media-probe-v0`: improve metadata evidence and diagnostics; keep unparsed metadata unknown; still no codec binary bundle.
3. `feat/system-playback-preview`: add system media playback surface; label path as system playback; record limitations.
4. `feat/d3d11-scrgb-test-pattern`: add D3D11 renderer project; static HDR test pattern only; no video frames.
5. `feat/video-frame-p010-path`: Media Foundation / D3D11 frame extraction; PQ/HLG shader conversion; video-only playback.

## Required PR review output

Every PR must include:

```text
Playback behavior changed: yes/no
Metadata detection changed: yes/no
Renderer path changed: yes/no
Licensing surface changed: yes/no
Bundled binaries added: yes/no
Sample media added: yes/no
Dolby Vision claim changed: yes/no
Validation commands:
Known limitations:
```

## Validation commands

```powershell
dotnet restore .\src\HDRVideoPlayer.App\HDRVideoPlayer.App.csproj
dotnet build .\src\HDRVideoPlayer.App\HDRVideoPlayer.App.csproj -c Debug
dotnet test .\tests\HDRVideoPlayer.Core.Tests\HDRVideoPlayer.Core.Tests.csproj -c Debug
.\scripts\public-safety-scan.ps1
git diff --check
```
