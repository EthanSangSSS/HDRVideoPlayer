# macOS Validation Matrix

## Capability states

| State | Meaning |
|---|---|
| `not_started` | No implementation exists |
| `detect_only` | Metadata or capability facts can be reported, without a presentation claim |
| `system_preview` | AVPlayer system preview is wired but not validated for presentation accuracy |
| `experimental` | A custom path exists but lacks repeatable validation |
| `validated` | A repeatable fixture and display matrix proves the bounded behavior |

## Current matrix

| Capability | Current state | Evidence / limitation | Next gate |
|---|---|---|---|
| SDR H.264 MP4 metadata | `detect_only` | Local AVFoundation record reported AVC and BT.709 matrix facts | Keep metadata facts separate from presentation |
| SDR H.264 MP4 AVPlayer open | `system_preview` | Local bounded run reached `ready` with no timeout | Presentation remains unverified |
| HEVC Main10 HDR10 metadata | `detect_only` | Local record reported HEVC, PQ, and BT.2020 facts; bit depth and mastering metadata remain unknown | Keep mastering metadata unknown until parsed |
| HEVC Main10 HDR10 AVPlayer open | `system_preview` | Local bounded run reached `ready` with no timeout | Do not infer HDR output accuracy |
| HLG metadata | `detect_only` | Local record reported HLG transfer and BT.2020 facts | Keep output transform unknown |
| HLG AVPlayer open | `system_preview` | Local bounded run reached `ready` with no timeout | Do not infer HLG presentation accuracy |
| Dolby Vision Profile 8.1 filename/metadata candidate | `detect_only` | The app still reports a filename candidate only; the local fixture was separately confirmed as Profile 8 with HDR10 compatibility id 1 | Add container parsing only in a separate metadata milestone |
| Dolby Vision Profile 8.1 system preview | `system_preview` | Local bounded run reached `ready`; readiness does not establish HDR10 fallback or Dolby Vision presentation | Keep presentation unknown |
| Dolby Vision Profile 5/7 detection-only | `detect_only` | A structural Profile 5 fixture exposed `dvhe` and reached `ready`; dynamic metadata application and color presentation were not validated | Keep Profile 5/7 detect-only |
| Unsupported system path | `system_preview` | A local unsupported-container video reached `failed` with no timeout | Preserve explicit failure reporting |
| EDR display diagnostic | `detect_only` | Local run recorded current and potential maximum EDR components of `1.00`; display support and current headroom were both false in that context | Run `chore/macos-edr-display-validation` where potential headroom is greater than `1.0` |
| Metal EDR test pattern | `experimental` | Separate executable configures `rgba16Float`, extended-linear-sRGB, and EDR opt-in; local unified-memory GPU readback preserved all eight bands through `4.00`; managed synchronization policy and asynchronous completion reporting are implemented, but Intel/discrete hardware is not locally exercised | Record current/potential/reference values and visible/clipping observations on an EDR-capable display; keep accuracy unverified |
| VideoToolbox custom frame path | `not_started` | No decoder or frame renderer exists | Start only after this fix and `chore/macos-edr-display-validation` are reviewed |

## Evidence rule

Metadata facts, AVPlayer state, display/EDR facts, and presentation accuracy are independent evidence. A `ready` state cannot promote HDR, HLG, or Dolby Vision presentation to `experimental` or `validated`.

Use [MACOS_LOCAL_VALIDATION.md](MACOS_LOCAL_VALIDATION.md) for the repository-external manifest and local report protocol. The full report, fixture names, hashes, paths, and media remain uncommitted; only a sanitized review summary may update this matrix.

## Sanitized local result

The repository-external six-category run completed on 2026-07-26 with no timeouts. SDR, HDR10, HLG, Profile 8.1, and structural Profile 5 fixtures reached AVPlayer `ready`; the unsupported-container fixture reached `failed`. All fixtures were locally generated, authorized test patterns. The Profile 5 fixture was detect-only and was not treated as colorimetrically valid. Visible presentation was not observed. Current and potential maximum EDR components were both `1.00`, so neither display support nor current headroom had positive evidence in that context; the rendering claim remained unknown and unverified.
