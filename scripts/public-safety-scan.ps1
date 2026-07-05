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
    if (-not (Test-Path -LiteralPath $path)) {
      continue
    }

    $item = Get-Item -LiteralPath $path
    $files = if ($item.PSIsContainer) {
      Get-ChildItem -LiteralPath $item.FullName -Recurse -File -ErrorAction SilentlyContinue
    } else {
      @($item)
    }

    foreach ($file in $files) {
      $matches = Select-String -LiteralPath $file.FullName -Pattern $pattern -SimpleMatch -ErrorAction SilentlyContinue
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
