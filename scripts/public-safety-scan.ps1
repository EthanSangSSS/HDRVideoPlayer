$ErrorActionPreference = "Stop"

$hardForbiddenPatterns = @(
  "we bypass DRM",
  "bypasses DRM",
  "certified Dolby Vision playback",
  "fully certified Dolby Vision",
  "pirated sample"
)

$paths = @("README.md", "AGENTS.md", "docs", ".github")
$hits = @()

foreach ($pattern in $hardForbiddenPatterns) {
  foreach ($path in $paths) {
    if (Test-Path $path) {
      $matches = Select-String -Path $path -Pattern $pattern -Recurse -SimpleMatch -ErrorAction SilentlyContinue
      foreach ($m in $matches) {
        $hits += "$($m.Path):$($m.LineNumber): $($m.Line)"
      }
    }
  }
}

$mediaFiles = Get-ChildItem -Path . -Recurse -File -Include *.mp4,*.mkv,*.mov,*.m4v,*.hevc,*.h265,*.av1 -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch "\\.git\\" }

if ($mediaFiles.Count -gt 0) {
  foreach ($file in $mediaFiles) {
    $hits += "Committed media file: $($file.FullName)"
  }
}

if ($hits.Count -gt 0) {
  Write-Host "Public safety scan failed:"
  $hits | ForEach-Object { Write-Host $_ }
  exit 1
}

Write-Host "Public safety scan passed."
