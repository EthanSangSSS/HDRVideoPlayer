namespace HDRVideoPlayer.Core.Media;

public sealed record MediaAsset(
    string FilePath,
    string FileName,
    string Container,
    IReadOnlyList<VideoStreamInfo> VideoStreams,
    IReadOnlyList<AudioStreamInfo> AudioStreams,
    HdrSignal HdrSignal,
    DolbyVisionInfo DolbyVision,
    PlaybackPath PlaybackPath
);

public sealed record VideoStreamInfo(
    int Index,
    string Codec,
    int? Width,
    int? Height,
    double? FrameRate,
    int? BitDepth,
    string PixelFormat
);

public sealed record AudioStreamInfo(
    int Index,
    string Codec,
    int? Channels,
    int? SampleRate
);
