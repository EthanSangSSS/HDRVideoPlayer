using HDRVideoPlayer.Core.Media;

namespace HDRVideoPlayer.Core.Diagnostics;

public sealed record DiagnosticReport(
    MediaAsset Asset,
    DateTimeOffset GeneratedAt,
    IReadOnlyList<string> Facts,
    IReadOnlyList<string> InferredFacts,
    IReadOnlyList<string> Unknowns,
    IReadOnlyList<string> Limitations,
    IReadOnlyList<string> NextTests
);

public static class DiagnosticReportFactory
{
    public static DiagnosticReport Create(MediaAsset asset)
    {
        var facts = new List<string>
        {
            $"File: {asset.FileName}",
            $"Container: {asset.Container}",
            $"Probe confidence: {asset.ProbeEvidence.Confidence}",
            $"Evidence sources: {string.Join(", ", asset.ProbeEvidence.Sources)}",
            $"Playback path: {asset.PlaybackPath.Kind}",
            $"Presentation path: {asset.PlaybackPath.Presentation}"
        };

        var inferredFacts = new List<string>();
        if (asset.DolbyVision.MarkersDetected)
        {
            inferredFacts.Add($"Dolby Vision filename-marker candidate: {asset.DolbyVision.ProfileCandidate}");
        }

        var unknowns = new[]
        {
            "Video codec, dimensions, frame rate, bit depth, and pixel format are not parsed.",
            "Color primaries, transfer function, matrix coefficients, and range are not parsed.",
            "Mastering display metadata, MaxCLL, and MaxFALL are not parsed.",
            "Dolby Vision profile, level, RPU, and base-layer compatibility are not parsed."
        };

        var limitations = new List<string>
        {
            asset.HdrSignal.Limitation,
            asset.DolbyVision.Limitation,
            asset.PlaybackPath.Limitation,
            asset.ProbeEvidence.Limitation
        }
        .Where(static item => !string.IsNullOrWhiteSpace(item))
        .Distinct()
        .ToArray();

        var nextTests = new[]
        {
            "Add Media Foundation metadata probe.",
            "Add system playback preview surface.",
            "Add D3D11 scRGB test-pattern renderer before claiming custom HDR video presentation."
        };

        return new DiagnosticReport(asset, DateTimeOffset.UtcNow, facts, inferredFacts, unknowns, limitations, nextTests);
    }
}
