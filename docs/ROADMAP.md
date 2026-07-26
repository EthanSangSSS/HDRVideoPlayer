# Roadmap

## Milestone 0 — Public scaffold

Status: complete.

Exit criteria:

- public-safe docs;
- buildable project skeleton;
- no bundled media;
- no codec binaries;
- no overclaiming.

## Milestone 1 — Shell validation

Status: complete.

- WinUI app builds.
- Core tests pass.
- File picker works.
- Diagnostic panel renders scaffold facts.

## Milestone 2 — Metadata probe v1

Status: in progress. Media Foundation stream attributes are implemented; fixture validation and JSON export remain.

- Replace extension heuristic with system metadata probe.
- Add stream model population.
- Add JSON diagnostic export.

## Milestone 3 — System playback preview

Status: in progress. The Windows system-media surface and runtime status are wired, and the local-only fixture protocol is available; local codec/container and presentation observations remain.

- Add playback surface.
- Use Windows system media path.
- Label exact playback limitations.

## Milestone 4 — D3D11 scRGB test-pattern renderer

- Add renderer project.
- Render static HDR patterns.
- Query monitor HDR state.
- Update diagnostics.

## Milestone 5 — Custom video frame path

- Media Foundation / D3D11 decode.
- P010/NV12 texture handling.
- PQ/HLG shader path.
- Video-only playback.

## Milestone 6 — Player basics

- Audio sync.
- Seek.
- Pause/play.
- Timeline.
- Error handling.

## Milestone 7 — Dolby Vision staged support

- Profile detection.
- Profile 8.1 fallback.
- Profile 5 / 7 detect-only.
- No certification claim.

## Parallel macOS track

The macOS track follows the same evidence boundaries but does not imply feature parity with Windows.

### macOS Milestone 0 — System preview scaffold

Status: implemented in the scaffold and exercised by the local system-preview matrix.

- Swift Package targeting macOS 13 or later.
- AppKit shell and AVPlayerView system preview.
- AVFoundation/CoreMedia metadata facts.
- Separate NSScreen potential-support, current-headroom, and reference EDR facts.
- Pure model and diagnostic tests.
- No custom Metal renderer or VideoToolbox frame path.

### macOS Milestone 1 — Local system-preview validation

Status: complete for the bounded local gate. The repository-external six-category run completed without timeouts, and only a sanitized summary is committed.

- Run authorized, uncommitted SDR, HDR10, HLG, Dolby Vision candidate, and unsupported fixtures.
- Record metadata, AVPlayer state, EDR/display observation, and presentation claim separately.

### macOS Milestone 2 — Metal EDR test pattern

Status: experimental. FP16 drawable configuration, unified-memory readback, managed-resource synchronization policy, and asynchronous command completion reporting are implemented. Intel/discrete hardware and visible EDR output remain unverified.

- Render a static EDR test pattern.
- Validate drawable format, EDR headroom, color-space assumptions, and measurement procedure.
- Do not add decoded video frames.

### macOS Milestone 2.1 — EDR display validation

- Branch: `chore/macos-edr-display-validation`.
- Require potential EDR headroom greater than `1.0`.
- Record display support, current headroom, and current/potential/reference values separately.
- Keep visible presentation accuracy unknown and unverified unless repeatable measurement supports a narrower claim.

### macOS Milestone 3 — Custom video-frame experiment

- Gate: review this evidence/readback fix and the `chore/macos-edr-display-validation` result first.
- Evaluate VideoToolbox, CVPixelBuffer, and Metal integration.
- Keep audio, timing, color conversion, and presentation validation as explicit gates.
