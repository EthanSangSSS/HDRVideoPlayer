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
| SDR H.264 MP4 metadata | `detect_only` | AVFoundation/CoreMedia probe exists; no authorized fixture result is committed | Compare against known-good local metadata |
| SDR H.264 MP4 AVPlayer open | `system_preview` | AVPlayer item readiness is observed | Record local `ready` or `failed` result |
| HEVC Main10 HDR10 metadata | `detect_only` | Public color properties are read when exposed; bit depth and mastering metadata may remain unknown | Validate with authorized Main10 fixture |
| HEVC Main10 HDR10 AVPlayer open | `system_preview` | System preview exists; codec and OS support vary | Record system state separately from display observation |
| HLG metadata | `detect_only` | HLG transfer is reported only when a public format-description value is exposed | Validate with authorized HLG fixture |
| HLG AVPlayer open | `system_preview` | AVPlayer readiness only | Record system state and EDR observation separately |
| Dolby Vision Profile 8.1 filename/metadata candidate | `detect_only` | Filename marker is low confidence; RPU, level, and base layer are not parsed | Compare with known-good local metadata |
| Dolby Vision Profile 8.1 system preview | `system_preview` | Readiness does not establish HDR10 fallback or Dolby Vision presentation | Run local fallback-oriented matrix without promoting rendering claim |
| Dolby Vision Profile 5/7 detection-only | `detect_only` | Filename candidate only; dynamic metadata application is absent | Keep detection-only until lawful public evidence exists |
| EDR display diagnostic | `detect_only` | `NSScreen` name and maximum EDR component value are reported | Record display mode and value on local hardware |
| Metal EDR test pattern | `not_started` | No custom renderer exists | Separate `feat/macos-edr-test-pattern` milestone after local validation |
| VideoToolbox custom frame path | `not_started` | No decoder or frame renderer exists | Start only after Metal EDR test-pattern validation |

## Evidence rule

Metadata facts, AVPlayer state, display/EDR facts, and presentation accuracy are independent evidence. A `ready` state cannot promote HDR, HLG, or Dolby Vision presentation to `experimental` or `validated`.
