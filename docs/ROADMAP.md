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
