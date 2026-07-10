using HDRVideoPlayer.Core.Media;

namespace HDRVideoPlayer.Core.Metadata;

public sealed class ExtensionHeuristicMediaProbe : IMediaProbe
{
    private static readonly HashSet<string> SupportedContainers = new(StringComparer.OrdinalIgnoreCase)
    {
        ".mp4", ".mov", ".m4v", ".mkv"
    };

    public MediaAsset Probe(string filePath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(filePath);

        var extension = Path.GetExtension(filePath);
        var fileName = Path.GetFileName(filePath);
        var hasSupportedContainer = SupportedContainers.Contains(extension);

        var container = hasSupportedContainer
            ? extension.TrimStart('.').ToUpperInvariant()
            : "UNKNOWN";

        var dolbyVision = DetectDolbyVisionMarker(fileName);
        var evidenceSources = new List<ProbeEvidenceSource>();
        if (hasSupportedContainer)
        {
            evidenceSources.Add(ProbeEvidenceSource.FileExtension);
        }

        if (dolbyVision.MarkersDetected)
        {
            evidenceSources.Add(ProbeEvidenceSource.FileNameMarker);
        }

        var playback = hasSupportedContainer
            ? new PlaybackPath(
                PlaybackPathKind.SystemMedia,
                PresentationPathKind.Unknown,
                "Windows system media path placeholder",
                "System playback is not yet wired. This is metadata scaffold output only.")
            : new PlaybackPath(
                PlaybackPathKind.Unsupported,
                PresentationPathKind.Unknown,
                "none",
                $"Extension '{extension}' is not in the initial container allowlist.");

        return new MediaAsset(
            filePath,
            fileName,
            container,
            Array.Empty<VideoStreamInfo>(),
            Array.Empty<AudioStreamInfo>(),
            HdrSignal.Unknown("HDR metadata parsing is not implemented in the extension heuristic probe."),
            dolbyVision,
            playback,
            new ProbeEvidence(
                evidenceSources.Count == 0 ? ProbeConfidence.Unknown : ProbeConfidence.Heuristic,
                evidenceSources.Count == 0 ? [ProbeEvidenceSource.None] : evidenceSources,
                "This probe uses file extension and optional filename markers only; it does not parse container or stream metadata."));
    }

    private static DolbyVisionInfo DetectDolbyVisionMarker(string fileName)
    {
        var marker = fileName.Contains("dovi", StringComparison.OrdinalIgnoreCase)
            || fileName.Contains("dolbyvision", StringComparison.OrdinalIgnoreCase)
            || fileName.Contains("dolby-vision", StringComparison.OrdinalIgnoreCase)
            || fileName.Contains("dolby_vision", StringComparison.OrdinalIgnoreCase);

        if (!marker)
        {
            return DolbyVisionInfo.Unknown;
        }

        return new DolbyVisionInfo(
            true,
            DetectProfileCandidate(fileName),
            "unknown",
            false,
            false,
            CapabilityState.DetectOnly,
            "Dolby Vision is a filename-marker candidate only. Container parsing and dynamic metadata application are not implemented.");
    }

    private static DolbyVisionProfileCandidate DetectProfileCandidate(string fileName)
    {
        if (fileName.Contains("8.1", StringComparison.OrdinalIgnoreCase)
            || fileName.Contains("p81", StringComparison.OrdinalIgnoreCase)
            || fileName.Contains("profile81", StringComparison.OrdinalIgnoreCase))
        {
            return DolbyVisionProfileCandidate.Profile81;
        }

        if (fileName.Contains("8.4", StringComparison.OrdinalIgnoreCase)
            || fileName.Contains("p84", StringComparison.OrdinalIgnoreCase)
            || fileName.Contains("profile84", StringComparison.OrdinalIgnoreCase))
        {
            return DolbyVisionProfileCandidate.Profile84;
        }

        if (fileName.Contains("p5", StringComparison.OrdinalIgnoreCase)
            || fileName.Contains("profile5", StringComparison.OrdinalIgnoreCase))
        {
            return DolbyVisionProfileCandidate.Profile5;
        }

        if (fileName.Contains("p7", StringComparison.OrdinalIgnoreCase)
            || fileName.Contains("profile7", StringComparison.OrdinalIgnoreCase))
        {
            return DolbyVisionProfileCandidate.Profile7;
        }

        return DolbyVisionProfileCandidate.Unknown;
    }
}
