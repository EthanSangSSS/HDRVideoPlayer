namespace HDRVideoPlayer.Core.Media;

public sealed record DolbyVisionInfo(
    bool MarkersDetected,
    DolbyVisionProfileCandidate ProfileCandidate,
    string LevelCandidate,
    bool RpuDetected,
    bool Hdr10CompatibleBaseLayer,
    CapabilityState State,
    string Limitation
)
{
    public static DolbyVisionInfo Unknown => new(
        false,
        DolbyVisionProfileCandidate.Unknown,
        "unknown",
        false,
        false,
        CapabilityState.NotStarted,
        "Dolby Vision parsing is not implemented. Dynamic metadata application is not implemented.");
}

public enum DolbyVisionProfileCandidate
{
    Unknown,
    Profile5,
    Profile7,
    Profile81,
    Profile84
}
