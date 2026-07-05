namespace HDRVideoPlayer.Core.Media;

public sealed record PlaybackPath(
    PlaybackPathKind Kind,
    PresentationPathKind Presentation,
    string Renderer,
    string Limitation
);

public enum PlaybackPathKind
{
    Unsupported,
    SystemMedia,
    MediaFoundation,
    CustomD3D11,
    ExternalLab
}

public enum PresentationPathKind
{
    Unknown,
    Sdr,
    Hdr10,
    Hlg,
    ScRgb,
    ToneMappedFallback
}
