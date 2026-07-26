# macOS Architecture

## Package layout

```text
macos/HDRVideoPlayerMac
  Package.swift
  Sources/HDRVideoPlayerMac
    main.swift
  Sources/HDRVideoPlayerMacEDRPattern
    main.swift
  Sources/HDRVideoPlayerMacLocalValidation
    HDRVideoPlayerMacLocalValidation.swift
  Sources/HDRVideoPlayerMacCore
    MacMediaModels.swift
    MacMetadataProbe.swift
    MacDiagnosticReport.swift
    MacDisplayDiagnostics.swift
    MacEDRTestPattern.swift
    MacLocalValidation.swift
    MacPlaybackState.swift
  Sources/HDRVideoPlayerMacMetal
    MacEDRMetalRenderer.swift
  Tests/HDRVideoPlayerMacCoreTests
    MacDiagnosticReportTests.swift
    MacEDRTestPatternTests.swift
    MacLocalValidationTests.swift
    MacMetadataModelTests.swift
    MacPlaybackStateTests.swift
  Tests/HDRVideoPlayerMacMetalTests
    MacEDRMetalRendererTests.swift
```

`HDRVideoPlayerMacCore` owns Swift-native models, metadata probing, display diagnostics, playback-state reduction, and report construction. `HDRVideoPlayerMac` owns AppKit lifecycle, the file picker, `AVPlayerView`, AVPlayer item observation, and presentation of system-preview diagnostics.

`HDRVideoPlayerMacMetal` owns only the static FP16 Metal pipeline and offscreen readback validator. `HDRVideoPlayerMacEDRPattern` owns its separate AppKit window and never receives a media URL or decoded frame.

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
      -> NSScreen name and current/potential/reference EDR component values
```

```text
MacEDRTestPatternConfiguration
  -> fixed extended-linear-sRGB color stops
  -> Metal fullscreen shader
  -> rgba16Float MTKView / CAMetalLayer EDR request
  -> separate NSScreen EDR diagnostics
  -> offscreen rgba16Float GPU readback tests
```

## Evidence separation

| Layer | What it may report | What it must not infer |
|---|---|---|
| Metadata facts | Track count, codec candidate, size, frame rate, color properties exposed by public APIs | Decode success or presentation accuracy |
| System playback state | AVPlayer item `idle`, `loading`, `ready`, or `failed` | HDR or Dolby Vision output correctness |
| Display / EDR capability | Screen name, maximum EDR component value, value greater than 1.0 | Video is using EDR or is color-accurate |
| Static Metal test-pattern facts | FP16 format, extended-linear-sRGB space, EDR request, submitted component values, GPU readback | Visible luminance, color accuracy, or any video rendering behavior |
| Presentation / rendering claim | Path is system AVPlayer or static Metal test pattern; accuracy remains unverified | HDR video accuracy, dynamic metadata application, or certification |

Both executables keep these layers separate. The system preview retains its bounded claim, and the test pattern reports: `Unknown and unverified. Static Metal EDR test pixels do not establish HDR or Dolby Vision video rendering accuracy.`

## Metadata probe

`MacMetadataProbe` accepts a local file URL and uses modern asynchronous AVFoundation loading. It reads public track properties and CoreMedia format-description extensions when available. Missing fields remain unknown.

If the URL is missing or AVFoundation loading fails, the probe returns a bounded fallback with only extension and filename-marker evidence. Dolby Vision profile candidates are filename-only unless a future public API exposes an explicit container fact. Playback support is never inferred from a filename.

## Display diagnostics

`MacDisplayDiagnostics` runs on the main actor because `NSScreen` is an AppKit object. It converts current, potential, and reference EDR component values into a pure `MacDisplayDiagnostic` value so EDR model behavior can be tested without a display or media fixture.

An EDR value above 1.0 means EDR headroom appears available for that screen. It is not evidence that AVPlayer selected an HDR path or that any output is accurate.

## Static Metal EDR path

The static renderer uses an `rgba16Float` MTKView, the extended-linear-sRGB color space, and `CAMetalLayer.wantsExtendedDynamicRangeContent`. A fullscreen shader draws eight fixed bands. Tests also render to an offscreen FP16 texture and read every band back from the GPU.

This validates the drawable configuration and submitted values only. Visible EDR output remains unknown until the pattern is observed or measured on an EDR-capable display using [MACOS_EDR_TEST_PATTERN.md](MACOS_EDR_TEST_PATTERN.md).

## Future paths

A later custom video path may evaluate VideoToolbox decode, CVPixelBuffer transfer, Metal textures, color conversion, timing, and audio synchronization. None of those components exists, and that work remains gated on separate EDR display validation.
