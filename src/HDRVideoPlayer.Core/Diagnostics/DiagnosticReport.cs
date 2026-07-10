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
            $"Evidence sources: {string.Join(", ", asset.ProbeEvidence.Sources)}"
        };

        var inferredFacts = new List<string>();
        if (asset.DolbyVision.MarkersDetected)
        {
            inferredFacts.Add($"Dolby Vision filename-marker candidate: {asset.DolbyVision.ProfileCandidate}");
        }

        var unknowns = new List<string>();
        if (asset.VideoStreams.Count == 0)
        {
            unknowns.Add("Video stream metadata is not available.");
        }

        foreach (var stream in asset.VideoStreams)
        {
            AddKnown(facts, stream.Codec, "unknown", $"Video stream {stream.Index} codec");
            AddKnown(facts, stream.Width, $"Video stream {stream.Index} width");
            AddKnown(facts, stream.Height, $"Video stream {stream.Index} height");
            AddKnown(facts, stream.FrameRate, $"Video stream {stream.Index} frame rate");
            AddKnown(facts, stream.BitDepth, $"Video stream {stream.Index} bit depth");
            AddKnown(facts, stream.PixelFormat, "unknown", $"Video stream {stream.Index} pixel format");

            if (stream.Codec == "unknown" || !stream.Width.HasValue || !stream.Height.HasValue
                || !stream.FrameRate.HasValue || !stream.BitDepth.HasValue || stream.PixelFormat == "unknown")
            {
                unknowns.Add($"Video stream {stream.Index} has one or more unavailable codec/format fields.");
            }
        }

        foreach (var stream in asset.AudioStreams)
        {
            AddKnown(facts, stream.Codec, "unknown", $"Audio stream {stream.Index} codec");
            AddKnown(facts, stream.Channels, $"Audio stream {stream.Index} channels");
            AddKnown(facts, stream.SampleRate, $"Audio stream {stream.Index} sample rate");
        }

        AddKnown(facts, asset.HdrSignal.Transfer, HdrTransfer.Unknown, "HDR transfer");
        AddKnown(facts, asset.HdrSignal.Primaries, ColorPrimaries.Unknown, "Color primaries");
        AddKnown(facts, asset.HdrSignal.Matrix, MatrixCoefficients.Unknown, "Matrix coefficients");
        AddKnown(facts, asset.HdrSignal.Range, VideoRange.Unknown, "Video range");
        AddKnown(facts, asset.HdrSignal.MaxCll, "MaxCLL");
        AddKnown(facts, asset.HdrSignal.MaxFall, "MaxFALL");
        AddKnown(facts, asset.HdrSignal.MasteringDisplayMetadata, "", "Mastering display luminance");

        if (asset.HdrSignal.Transfer == HdrTransfer.Unknown
            || asset.HdrSignal.Primaries == ColorPrimaries.Unknown
            || asset.HdrSignal.Matrix == MatrixCoefficients.Unknown
            || asset.HdrSignal.Range == VideoRange.Unknown)
        {
            unknowns.Add("One or more HDR color attributes are unavailable.");
        }

        if (!asset.HdrSignal.MaxCll.HasValue || !asset.HdrSignal.MaxFall.HasValue
            || string.IsNullOrWhiteSpace(asset.HdrSignal.MasteringDisplayMetadata))
        {
            unknowns.Add("One or more mastering-display, MaxCLL, or MaxFALL fields are unavailable.");
        }

        unknowns.Add("Dolby Vision profile, level, RPU, and base-layer compatibility are not parsed from container metadata.");

        var limitations = new List<string>
        {
            asset.HdrSignal.Limitation,
            asset.DolbyVision.Limitation,
            asset.ProbeEvidence.Limitation
        }
        .Where(static item => !string.IsNullOrWhiteSpace(item))
        .Distinct()
        .ToArray();

        var nextTests = new[]
        {
            "Validate Media Foundation fields against locally licensed MP4 and MOV fixtures.",
            "Add a bounded container parser for Dolby Vision private metadata before promoting profile candidates.",
            "Validate Windows system playback against a local codec and container matrix.",
            "Add D3D11 scRGB test-pattern renderer before claiming custom HDR video presentation."
        };

        return new DiagnosticReport(asset, DateTimeOffset.UtcNow, facts, inferredFacts, unknowns, limitations, nextTests);
    }

    private static void AddKnown<T>(ICollection<string> facts, T? value, string label) where T : struct
    {
        if (value.HasValue)
        {
            facts.Add($"{label}: {value.Value}");
        }
    }

    private static void AddKnown<T>(ICollection<string> facts, T value, T unknown, string label) where T : struct
    {
        if (!EqualityComparer<T>.Default.Equals(value, unknown))
        {
            facts.Add($"{label}: {value}");
        }
    }

    private static void AddKnown(ICollection<string> facts, string value, string unknown, string label)
    {
        if (!string.IsNullOrWhiteSpace(value) && !string.Equals(value, unknown, StringComparison.OrdinalIgnoreCase))
        {
            facts.Add($"{label}: {value}");
        }
    }
}
