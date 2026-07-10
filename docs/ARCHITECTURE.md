# Architecture

## Influence

HDRImageViewer demonstrates that a WinUI 3 + Direct3D 11 + FP16 scRGB path can be a credible foundation for HDR presentation. HDRVideoPlayer should adapt that architecture to time-based media while keeping a clean boundary between ideas, code, and license obligations.

## High-level pipeline

```text
FileOpenPicker
  -> MediaAsset
  -> MetadataProbe
      -> container facts
      -> video stream facts
      -> HDR signal
      -> Dolby Vision marker/profile candidate
  -> PlaybackController
      -> system media preview
      -> Media Foundation path
      -> custom D3D11 path
  -> Renderer
      -> decode surface
      -> color transform
      -> tone map / gamut map
      -> FP16 scRGB swap chain
  -> Diagnostics
      -> metadata facts and limitations
      -> system playback runtime state
      -> presentation / rendering claim
      -> next tests
```

## Projects

```text
src/HDRVideoPlayer.App
  WinUI shell, file picker, diagnostics UI.

src/HDRVideoPlayer.Core
  Domain models, metadata probe contracts, diagnostic report factory.

future: src/HDRVideoPlayer.Renderer.D3D11
  D3D11 device, swap chain, color transforms, shaders.

future: src/HDRVideoPlayer.MediaFoundation
  Source reader / media engine / D3D11 hardware decode bridge.

tests/HDRVideoPlayer.Core.Tests
  Pure domain-model tests.
```

## Playback modes

| Mode | Meaning |
|---|---|
| Unsupported | No known playback path |
| SystemMedia | Windows system media stack owns decode/presentation |
| MediaFoundation | App controls Media Foundation pipeline |
| CustomD3D11 | App owns frame rendering |
| ExternalLab | Optional user-provided tool path for metadata or experiments |

## Presentation modes

| Mode | Meaning |
|---|---|
| SDR | SDR output |
| HDR10 | HDR10 output path |
| HLG | HLG output path |
| scRGB | FP16 scRGB compositor path |
| ToneMappedFallback | HDR content mapped to SDR or display-limited output |
| Unknown | Not yet determined |

## Diagnostic separation

- Metadata facts report only attributes read by the probe.
- System playback state reports whether the Windows media stack opened or rejected the source.
- Presentation remains `Unknown` until output behavior is independently measured; successful system playback is not an HDR or Dolby Vision rendering claim.

## First custom-renderer milestone

After the system-media preview is validated, implement a static HDR test-pattern renderer. This proves:

- D3D device lifecycle;
- swap-chain integration;
- display HDR detection;
- scRGB presentation;
- diagnostics contract.
