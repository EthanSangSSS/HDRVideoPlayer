namespace HDRVideoPlayer.Core.Media;

public sealed record DolbyVisionInfo(
    bool MarkersDetected,
    string ProfileCandidate,
    string LevelCandidate,
    bool RpuDetected,
    bool Hdr10CompatibleBaseLayer,
    CapabilityState State,
    string Limitation
)
{
    public static DolbyVisionInfo Unknown => new(
        false,
        "unknown",
        "unknown",
        false,
        false,
        CapabilityState.NotStarted,
        "Dolby Vision parsing is not implemented. Early builds may only show extension/container heuristics.");
}
