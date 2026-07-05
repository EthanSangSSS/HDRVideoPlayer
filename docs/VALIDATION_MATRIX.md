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
| HDR10 metadata | not_started | Media Foundation / parser probe |
| HLG metadata | not_started | Media Foundation / parser probe |
| Dolby Vision marker detection | not_started | profile candidate panel |
| System playback | not_started | `SystemMedia` path |
| D3D11 scRGB renderer | not_started | static test pattern |
| P010/NV12 video frame path | not_started | custom frame rendering |
| Audio sync | not_started | basic player usability |
| Profile 8.1 fallback | not_started | HDR10 base-layer fallback |
| Profile 5 rendering | not_started | no early claim |
| Profile 7 FEL/MEL rendering | not_started | no early claim |

## Evidence rule

Every feature PR must update this matrix or explain why no validation state changed.
