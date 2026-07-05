namespace HDRVideoPlayer.Core.Media;

public sealed record HdrSignal(
    HdrTransfer Transfer,
    ColorPrimaries Primaries,
    MatrixCoefficients Matrix,
    int? BitDepth,
    int? MaxCll,
    int? MaxFall,
    string MasteringDisplayMetadata,
    CapabilityState State,
    string Limitation
)
{
    public static HdrSignal Unknown(string limitation) => new(
        HdrTransfer.Unknown,
        ColorPrimaries.Unknown,
        MatrixCoefficients.Unknown,
        null,
        null,
        null,
        "",
        CapabilityState.NotStarted,
        limitation);
}

public enum HdrTransfer
{
    Unknown,
    Sdr,
    Pq,
    Hlg
}

public enum ColorPrimaries
{
    Unknown,
    Bt709,
    Bt2020,
    DisplayP3
}

public enum MatrixCoefficients
{
    Unknown,
    Bt709,
    Bt2020NonConstantLuminance,
    Bt2020ConstantLuminance
}

public enum CapabilityState
{
    NotStarted,
    DetectOnly,
    FallbackPlayback,
    Experimental,
    Validated
}
