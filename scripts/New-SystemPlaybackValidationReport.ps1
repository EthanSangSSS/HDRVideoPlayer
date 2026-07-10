[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$FixtureManifest,

  [string]$OutputPath = (Join-Path $PSScriptRoot "..\\artifacts\\system-playback-validation\\system-playback-validation-$(Get-Date -Format 'yyyyMMdd-HHmmss').md")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$allowedCategories = @(
  "sdr_h264_mp4",
  "hdr10_hevc_main10",
  "hlg",
  "dolby_vision_profile_8_1_fallback",
  "dolby_vision_profile_5_or_7_detect_only",
  "unsupported_or_missing_codec"
)

if (-not (Test-Path -LiteralPath $FixtureManifest -PathType Leaf)) {
  throw "Fixture manifest was not found: $FixtureManifest"
}

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$resolvedManifestPath = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $FixtureManifest).Path)
if ($resolvedManifestPath.StartsWith($repositoryRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Fixture manifest must stay outside the repository: $resolvedManifestPath"
}

try {
  $fixtures = @(Get-Content -LiteralPath $resolvedManifestPath -Raw | ConvertFrom-Json)
}
catch {
  throw "Fixture manifest must be valid JSON: $($_.Exception.Message)"
}

if ($fixtures.Count -eq 0) {
  throw "Fixture manifest must contain at least one fixture."
}

$fixtureIds = @{}
foreach ($fixture in $fixtures) {
  foreach ($propertyName in @("id", "category", "path")) {
    if ([string]::IsNullOrWhiteSpace([string]$fixture.$propertyName)) {
      throw "Each fixture requires a non-empty '$propertyName' property."
    }
  }

  if ($fixtureIds.ContainsKey($fixture.id)) {
    throw "Fixture id '$($fixture.id)' is duplicated."
  }
  $fixtureIds[$fixture.id] = $true

  if ($allowedCategories -notcontains $fixture.category) {
    throw "Fixture '$($fixture.id)' has unsupported category '$($fixture.category)'."
  }
}

$missingCategories = $allowedCategories | Where-Object { $_ -notin $fixtures.category }
if ($missingCategories.Count -gt 0) {
  throw "Fixture manifest is missing required categories: $($missingCategories -join ', ')."
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
  New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$hevcPackages = @()
if (Get-Command Get-AppxPackage -ErrorAction SilentlyContinue) {
  $hevcPackages = @(Get-AppxPackage | Where-Object { $_.Name -like "*HEVC*" } | Select-Object -ExpandProperty Name)
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# System Playback Validation Record")
$lines.Add("")
$lines.Add("Generated: $(Get-Date -Format 'o')")
$lines.Add("Host: $env:COMPUTERNAME")
$lines.Add("Windows: $([System.Environment]::OSVersion.VersionString)")
$lines.Add("HEVC AppX packages: $(if ($hevcPackages.Count -gt 0) { $hevcPackages -join ', ' } else { 'none detected' })")
$lines.Add("")
$lines.Add("This record contains no media. A Windows source opening only proves the system-media path reached Ready; it does not prove HDR, HLG, or Dolby Vision presentation accuracy. Keep the presentation claim below unchanged.")

foreach ($fixture in $fixtures) {
  $exists = Test-Path -LiteralPath $fixture.path -PathType Leaf
  $fileName = if ($exists) { Split-Path -Leaf $fixture.path } else { "not found" }
  $fileHash = if ($exists) { (Get-FileHash -Algorithm SHA256 -LiteralPath $fixture.path).Hash } else { "not available" }
  $fixtureNotes = if ($fixture.PSObject.Properties.Match("notes").Count -gt 0) { [string]$fixture.notes } else { "none" }
  $fixtureNotes = $fixtureNotes.Replace("|", "\\|")

  $lines.Add("")
  $lines.Add("## $($fixture.id)")
  $lines.Add("")
  $lines.Add("| Field | Record |")
  $lines.Add("|---|---|")
  $lines.Add("| Scenario | $($fixture.category) |")
  $lines.Add("| Local file present | $(if ($exists) { 'yes' } else { 'no' }) |")
  $lines.Add("| File name | $fileName |")
  $lines.Add("| SHA-256 | $fileHash |")
  $lines.Add("| Fixture notes | $fixtureNotes |")
  $lines.Add("| Metadata facts observed in the app | not_recorded |")
  $lines.Add("| Windows system playback state | not_run (record Ready or Failed from the app) |")
  $lines.Add("| Visible presentation observation | not_observed |")
  $lines.Add("| Presentation / rendering claim | Unknown and unverified; no custom HDR or Dolby Vision rendering accuracy claim. |")
  $lines.Add("| Follow-up | not_recorded |")
}

$lines.Add("")
$lines.Add("## Recording Rules")
$lines.Add("")
$lines.Add("- Copy only the app's Metadata facts into the metadata row; leave inferred facts, unknowns, and limitations distinct.")
$lines.Add("- Record the actual Windows system state as Ready or Failed. Do not replace it with an expected result.")
$lines.Add("- Visible observation is an operator note, not a measurement or rendering certification.")
$lines.Add("- Do not add local media, full local paths, or fixture manifest files to Git.")

Set-Content -LiteralPath $OutputPath -Value $lines -Encoding utf8
Write-Host "Validation record created: $OutputPath"
