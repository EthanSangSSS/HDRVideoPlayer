# System Playback Validation

This procedure validates the Windows system-media preview with locally licensed fixtures that remain outside the repository. It records three independent observations:

1. metadata facts exposed by the Media Foundation probe;
2. Windows system playback state (`Ready` or `Failed`);
3. visible presentation observation.

It does not validate a custom renderer, HDR output accuracy, Dolby Vision output accuracy, certification, codec licensing, or DRM behavior.

## Fixture boundary

Use only local, authorized media. Do not commit fixtures, generated records, or the local manifest. The repository ignores `samples/media/` and `artifacts/`; the example manifest is data-only and contains no media.

Copy [system-playback-fixtures.example.json](../scripts/fixtures/system-playback-fixtures.example.json) outside the repository, replace every path with a local absolute path, and preserve all six categories. The report generator rejects manifests located inside the repository.

- `sdr_h264_mp4`
- `hdr10_hevc_main10`
- `hlg`
- `dolby_vision_profile_8_1_fallback`
- `dolby_vision_profile_5_or_7_detect_only`
- `unsupported_or_missing_codec`

The last category may use a source expected to fail or a Windows installation without the required codec. A `Ready` result for Profile 8.1 is system behavior only; it is not a Dolby Vision presentation claim. Profile 5 and Profile 7 remain detection-only cases.

## Run on Windows

From the repository root, first run the standard checks:

```powershell
.\scripts\validate-local.ps1
```

Create a local observation record. The default output is ignored under `artifacts/`.

```powershell
.\scripts\New-SystemPlaybackValidationReport.ps1 `
  -FixtureManifest C:\private\hdrvideoplayer-fixtures.json
```

Run the app and select each fixture with the file picker:

```powershell
dotnet run --project .\src\HDRVideoPlayer.App\HDRVideoPlayer.App.csproj -c Debug
```

For each generated record section, replace only the placeholder values after observing the app:

| Field | Record from the app |
|---|---|
| Metadata facts observed in the app | Copy values from **Metadata facts** only. Keep inferred facts, unknowns, and limitations out of this row. |
| Windows system playback state | Copy `Ready` or `Failed` from **System playback path**. `Ready` means Windows opened the source, not that playback or presentation is correct. |
| Visible presentation observation | Record the display mode and visible result as an operator observation. State `not_observed` when no suitable HDR display path is available. |
| Presentation / rendering claim | Leave as `Unknown and unverified; no custom HDR or Dolby Vision rendering accuracy claim.` |

At the end, record the Windows version, display mode, HEVC package detection reported by the script, and any failure text shown by the app. Keep the record local unless a separate review deliberately removes local paths and media-identifying information.

## Acceptance rule

This milestone becomes `validated` only after all six categories have a repeatable, reviewable local record with the three layers kept separate. A positive playback result alone cannot promote HDR, HLG, or Dolby Vision presentation status.
