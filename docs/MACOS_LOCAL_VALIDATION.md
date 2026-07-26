# macOS Local Validation

This procedure records the macOS system-preview matrix with locally authorized fixtures that remain outside the repository. It keeps five evidence layers separate:

1. AVFoundation and CoreMedia metadata facts;
2. inferred filename or extension facts;
3. AVPlayer item state (`ready`, `failed`, or `timed_out`);
4. NSScreen display and EDR capability facts;
5. presentation accuracy, which remains unknown and unverified.

It does not validate a custom renderer, HDR output accuracy, Dolby Vision output accuracy, certification, codec licensing, or DRM behavior.

## Fixture boundary

Keep the manifest and every media file outside the repository. Use only media that is authorized for local validation. Do not commit the manifest, generated report, hashes, file names, or media.

Start from [macos-local-validation-fixtures.example.json](../scripts/fixtures/macos-local-validation-fixtures.example.json), create a local copy outside the repository, and replace each placeholder path. The validator requires at least one fixture in every category:

- `sdr_h264_mp4`
- `hdr10_hevc_main10`
- `hlg`
- `dolby_vision_profile_8_1_fallback`
- `dolby_vision_profile_5_or_7_detect_only`
- `unsupported_or_missing_codec`

The Profile 8.1 case is fallback-oriented only. Profile 5 and Profile 7 remain detection-only. A ready result in any category is a system AVPlayer fact, not a rendering claim.

## Run on macOS

From the repository root, run the package checks:

```bash
swift build --package-path macos/HDRVideoPlayerMac
swift test --package-path macos/HDRVideoPlayerMac
```

Generate the local record. The default output is ignored under `artifacts/macos-local-validation/`.

```bash
swift run --package-path macos/HDRVideoPlayerMac HDRVideoPlayerMacLocalValidation \
  --manifest /absolute/path/macos-local-validation-fixtures.json
```

The validator:

- rejects manifests and media inside the repository;
- requires absolute paths and all six categories;
- records only file basenames and SHA-256 values, never absolute media paths;
- reuses `MacMetadataProbe` for AVFoundation/CoreMedia facts;
- waits up to 15 seconds for AVPlayer `ready` or `failed` per fixture;
- records the current NSScreen name and maximum EDR component value;
- leaves visible presentation observation as `not_observed`;
- preserves the exact presentation claim: `Unknown and unverified. No custom Metal HDR or Dolby Vision rendering accuracy claim.`

Use `--timeout-seconds` only when a slow local source needs a longer bounded wait. A `timed_out` result makes the run incomplete and returns a nonzero exit after writing the report.

For an optional operator observation, run the app and open each fixture with the file picker:

```bash
swift run --package-path macos/HDRVideoPlayerMac HDRVideoPlayerMac
```

Edit only the ignored local report. Record what was visibly observed and the display mode; do not convert that observation into a color-accuracy or Dolby Vision claim.

## Acceptance rule

This milestone is ready for review only when:

- all six categories have local records;
- every fixture reaches an actual `ready` or `failed` state, with no timeout;
- metadata facts and inferred facts remain in separate rows;
- NSScreen EDR facts are recorded separately from playback state;
- the presentation claim remains unknown and unverified;
- `git status --short` shows no media, local manifest, or generated report.

Only a sanitized summary may be added to the repository. Keep fixture names, hashes, paths, and the full local report private. The next `feat/macos-edr-test-pattern` branch remains blocked until this local matrix is reviewed; that later branch may render only a static Metal EDR pattern and must not accept decoded video frames.
