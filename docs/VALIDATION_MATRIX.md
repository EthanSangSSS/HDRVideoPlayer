# Validation Matrix

## Capability states

| State | Meaning |
|---|---|
| `not_started` | No implementation |
| `detect_only` | Metadata detection only |
| `fallback_playback` | Playback works through fallback path |
| `experimental` | Custom path exists but is not validated |
| `validated` | Repeatable test matrix proves behavior |

## Initial matrix

| Capability | Current state | Target |
|---|---|---|
| Open MP4/MOV/MKV path | detect_only | file picker creates `MediaAsset` |
| Container classification | detect_only | extension heuristic first |
| Video/audio stream metadata | detect_only | Media Foundation media-type attributes on Windows |
| HDR10 metadata | detect_only | PQ/BT.2020/luminance attributes when exposed by Media Foundation |
| HLG metadata | detect_only | HLG/BT.2020 attributes when exposed by Media Foundation |
| Dolby Vision filename-marker candidate detection | detect_only | filename marker only; no container parsing or dynamic metadata application |
| System playback preview | experimental | `MediaPlayerElement` open/ready/failed state; local fixture protocol and record generator exist, but no Windows fixture observations are committed |
| D3D11 scRGB renderer | not_started | static test pattern |
| P010/NV12 video frame path | not_started | custom frame rendering |
| Audio sync | not_started | basic player usability |
| Profile 8.1 fallback | not_started | HDR10 base-layer fallback |
| Profile 5 rendering | not_started | no early claim |
| Profile 7 FEL/MEL rendering | not_started | no early claim |

Probe v1 reads Media Foundation stream and media-type attributes on Windows, then falls back to v0 heuristics when unavailable. Missing attributes remain unknown. It does not parse mastering chromaticity coordinates, Dolby Vision private metadata, or dynamic metadata application.

See `docs/SYSTEM_PLAYBACK_VALIDATION.md` for the local-only fixture protocol. A Windows `Ready` event is evidence only for the system-media open path and does not change the presentation claim.

## Evidence rule

Every feature PR must update this matrix or explain why no validation state changed.
