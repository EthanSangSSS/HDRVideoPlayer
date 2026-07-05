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

        var container = SupportedContainers.Contains(extension)
            ? extension.TrimStart('.').ToUpperInvariant()
            : "UNKNOWN";

        var playback = SupportedContainers.Contains(extension)
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
            DolbyVisionInfo.Unknown,
            playback);
    }
}
