# macOS Architecture

## Package layout

```text
macos/HDRVideoPlayerMac
  Package.swift
  Sources/HDRVideoPlayerMac
    main.swift
  Sources/HDRVideoPlayerMacCore
    MacMediaModels.swift
    MacMetadataProbe.swift
    MacDiagnosticReport.swift
    MacDisplayDiagnostics.swift
    MacPlaybackState.swift
  Tests/HDRVideoPlayerMacCoreTests
    MacDiagnosticReportTests.swift
    MacMetadataModelTests.swift
    MacPlaybackStateTests.swift
```

`HDRVideoPlayerMacCore` owns Swift-native models, metadata probing, display diagnostics, playback-state reduction, and report construction. `HDRVideoPlayerMac` owns AppKit lifecycle, the file picker, `AVPlayerView`, AVPlayer item observation, and presentation of diagnostics.

## Current pipeline

```text
NSOpenPanel
  -> local file URL
  -> MacMetadataProbe
      -> extension and filename fallback
      -> AVFoundation tracks
      -> CoreMedia format-description extensions
  -> MacDiagnosticReportFactory
  -> AVPlayerItem / AVPlayer / AVPlayerView
      -> idle / loading / ready / failed
  -> MacDisplayDiagnostics
      -> NSScreen name and maximum EDR component value
```

## Evidence separation

| Layer | What it may report | What it must not infer |
|---|---|---|
| Metadata facts | Track count, codec candidate, size, frame rate, color properties exposed by public APIs | Decode success or presentation accuracy |
| System playback state | AVPlayer item `idle`, `loading`, `ready`, or `failed` | HDR or Dolby Vision output correctness |
| Display / EDR capability | Screen name, maximum EDR component value, value greater than 1.0 | Video is using EDR or is color-accurate |
| Presentation / rendering claim | Path is system AVPlayer; accuracy remains unverified | Custom rendering, dynamic metadata application, or certification |

The UI keeps these layers in separate sections. The presentation text remains: `Unknown and unverified. No custom Metal HDR or Dolby Vision rendering accuracy claim.`

## Metadata probe

`MacMetadataProbe` accepts a local file URL and uses modern asynchronous AVFoundation loading. It reads public track properties and CoreMedia format-description extensions when available. Missing fields remain unknown.

If the URL is missing or AVFoundation loading fails, the probe returns a bounded fallback with only extension and filename-marker evidence. Dolby Vision profile candidates are filename-only unless a future public API exposes an explicit container fact. Playback support is never inferred from a filename.

## Display diagnostics

`MacDisplayDiagnostics` runs on the main actor because `NSScreen` is an AppKit object. It converts the current screen into a pure `MacDisplayDiagnostic` value so EDR model behavior can be tested without a display or media fixture.

An EDR value above 1.0 means EDR headroom appears available for that screen. It is not evidence that AVPlayer selected an HDR path or that any output is accurate.

## Future paths

The next rendering experiment is a static Metal EDR test pattern. It must remain independent from AVPlayer system preview and must establish drawable format, EDR range, and measurement procedure before any video-frame work.

A later custom video path may evaluate VideoToolbox decode, CVPixelBuffer transfer, Metal textures, color conversion, timing, and audio synchronization. None of those components exists in this scaffold.
