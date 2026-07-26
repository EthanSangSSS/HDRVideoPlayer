# macOS Feasibility

## Conclusion

A native macOS track is feasible as a parallel, experimental scaffold. AVFoundation and AVKit provide a system-owned path for local file metadata and preview, while AppKit supplies a small native shell and `NSScreen` exposes display EDR capability facts. These APIs are sufficient for the first milestone without adding codec binaries, a custom decoder, or a custom renderer.

The macOS track is not feature-parity with the Windows track. Both tracks share an evidence-first diagnostic policy, but their platform APIs and future rendering paths remain independent.

## First milestone

The first milestone uses:

- AppKit for the executable shell and local file picker;
- AVKit `AVPlayerView` and AVFoundation `AVPlayer` for system-media preview;
- AVFoundation tracks and CoreMedia format-description extensions for available metadata facts;
- `NSScreen.maximumExtendedDynamicRangeColorComponentValue` for an EDR capability observation;
- a Swift Package so source, targets, and tests remain reviewable without generated Xcode project files.

An AVPlayer item reaching `readyToPlay` means the system accepted the source sufficiently to prepare the item. It does not prove sustained playback, HDR output accuracy, Dolby Vision output accuracy, or the existence of a custom renderer.

The file picker permits MP4, MOV, M4V, and MKV selection. MKV acceptance and playback are system-dependent and must be recorded from the actual AVPlayer state.

## Why Metal is later

A custom Metal path requires separate proof for drawable formats, EDR headroom, color transforms, pixel-buffer formats, synchronization, and output measurements. Adding it to the system-preview scaffold would collapse system playback and custom presentation into one untestable claim.

The renderer milestone is now implemented as a separate static Metal EDR test pattern. A VideoToolbox, CVPixelBuffer, and Metal video-frame path comes only after that test-pattern path is observed on an EDR-capable display.

## Dolby Vision boundary

This scaffold treats Dolby Vision as detection-only:

- filename markers can create a low-confidence profile candidate;
- public AVFoundation/CoreMedia metadata may be reported only when it is an explicit fact;
- AVPlayer readiness never implies Dolby Vision rendering or dynamic metadata application;
- Profile 8.1 fallback behavior requires a separate local fixture matrix;
- Profile 5 and Profile 7 remain detection-only.

No Dolby SDK, certification claim, protected-media handling, or dynamic metadata renderer is included.

## Platform comparison

| Concern | Windows track | macOS track |
|---|---|---|
| Application shell | WinUI 3 / C# | AppKit / Swift |
| System metadata | Media Foundation | AVFoundation / CoreMedia |
| System preview | `MediaPlayerElement` | `AVPlayerView` / `AVPlayer` |
| Display capability | Future DXGI/HDR diagnostics | `NSScreen` EDR facts |
| Test renderer | D3D11 FP16 scRGB | Isolated Metal `rgba16Float` EDR test pattern |
| Future custom frames | Media Foundation + D3D11 | VideoToolbox + CVPixelBuffer + Metal |

## Public boundary

- No DRM handling or circumvention.
- No codec binaries or third-party media libraries.
- No bundled or committed media samples.
- No Dolby SDKs.
- The custom Metal scope is limited to fixed test pixels; no decoded video frames are accepted.
- No HDR or Dolby Vision presentation-accuracy claim.
- No Dolby Vision certification claim.
