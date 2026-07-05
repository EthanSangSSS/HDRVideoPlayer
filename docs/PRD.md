# PRD — HDRVideoPlayer

## One-line product definition

HDRVideoPlayer is a Windows local video player and diagnostic workbench for HDR10, HLG, and staged Dolby Vision playback support.

## User problem

Existing desktop video players may show HDR video but often hide the playback chain:

- content metadata;
- decoder path;
- bit-depth handling;
- color-space conversion;
- output color space;
- monitor HDR state;
- Dolby Vision profile and fallback behavior.

## Target users

1. HDR display power users.
2. Media pipeline developers.
3. Video toolchain testers.
4. Display / device quality engineers.
5. Portfolio reviewers evaluating graphics and systems engineering skill.

## MVP

### P0 — metadata-first app shell

- Open local media file.
- Create diagnostic report from file path and metadata probe.
- Display exact implementation state.
- Avoid playback accuracy claims.

### P1 — video metadata probe

- Container.
- Codec.
- Resolution.
- Frame rate.
- Bit depth.
- Pixel format.
- Transfer function.
- Primaries.
- Matrix.
- Mastering display metadata.
- MaxCLL / MaxFALL.
- Dolby Vision profile candidate.

### P2 — system playback preview

- Play using Windows media path.
- Label as system playback.
- Display caveats.

### P3 — custom scRGB renderer

- D3D11 device.
- FP16 scRGB swap chain.
- Static HDR test pattern.
- Display capability diagnostics.

### P4 — custom frame path

- P010 / NV12 frame access.
- YUV to RGB shader.
- PQ / HLG to scRGB.
- Frame scheduling.

### P5 — Dolby Vision staged support

- Detect profile candidate.
- Profile 8.1 HDR10-compatible fallback.
- Profile 5 / 7 classification.
- No certification claim.

## Success criteria

- The project is honest about unsupported states.
- It distinguishes detection, fallback playback, experimental rendering, and validated rendering.
- It produces repeatable diagnostics for every file.
- It becomes useful even before perfect playback by exposing the media/display pipeline.
