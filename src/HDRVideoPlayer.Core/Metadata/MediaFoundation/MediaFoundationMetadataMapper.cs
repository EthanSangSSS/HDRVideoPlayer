using HDRVideoPlayer.Core.Media;

namespace HDRVideoPlayer.Core.Metadata.MediaFoundation;

internal static class MediaFoundationMetadataMapper
{
    internal static readonly Guid MediaTypeVideo = new("73646976-0000-0010-8000-00AA00389B71");
    internal static readonly Guid MediaTypeAudio = new("73647561-0000-0010-8000-00AA00389B71");
    internal static readonly Guid MajorType = new("48EBA18E-F8C9-4687-BF11-0A74C9F96A8F");
    internal static readonly Guid Subtype = new("F7E34C9A-42E8-4714-B74B-CB29D72C35E5");
    internal static readonly Guid FrameSize = new("1652C33D-D6B2-4012-B834-72030849A37D");
    internal static readonly Guid FrameRate = new("C459A2E8-3D2C-4E44-B132-FEE5156C7BB0");
    internal static readonly Guid TransferFunction = new("5FB0FCE9-BE5C-4935-A811-EC838F8EED93");
    internal static readonly Guid VideoPrimaries = new("DBFBE4D7-0740-4EE0-8192-850AB0E21935");
    internal static readonly Guid YuvMatrix = new("3E23D450-2C75-4D25-A00E-B91670D12327");
    internal static readonly Guid VideoNominalRange = new("C21B8EE5-B956-4071-8DAF-325EDF5CAB11");
    internal static readonly Guid MaxLuminanceLevel = new("50253128-C110-4DE4-98AE-46A324FAE6DA");
    internal static readonly Guid MaxFrameAverageLuminanceLevel = new("58D4BF57-6F52-4733-A195-A9E29ECF9E27");
    internal static readonly Guid MaxMasteringLuminance = new("D6C6B997-272F-4CA1-8D00-8042111A0FF6");
    internal static readonly Guid MinMasteringLuminance = new("839A4460-4E7E-4B4F-AE79-CC08905C7B27");
    internal static readonly Guid AudioChannels = new("37E48BF5-645E-4C5B-89DE-ADA9E29B696A");
    internal static readonly Guid AudioSampleRate = new("5FAEEAE7-0290-4C31-9E8A-C534F68D9DBA");

    internal static HdrTransfer MapTransfer(uint value) => value switch
    {
        4 or 5 or 7 or 11 or 12 or 13 => HdrTransfer.Sdr,
        15 => HdrTransfer.Pq,
        16 => HdrTransfer.Hlg,
        _ => HdrTransfer.Unknown
    };

    internal static ColorPrimaries MapPrimaries(uint value) => value switch
    {
        2 => ColorPrimaries.Bt709,
        9 => ColorPrimaries.Bt2020,
        13 => ColorPrimaries.DisplayP3,
        _ => ColorPrimaries.Unknown
    };

    internal static MatrixCoefficients MapMatrix(uint value) => value switch
    {
        1 => MatrixCoefficients.Bt709,
        4 or 5 => MatrixCoefficients.Bt2020NonConstantLuminance,
        _ => MatrixCoefficients.Unknown
    };

    internal static VideoRange MapRange(uint value) => value switch
    {
        1 => VideoRange.Full,
        2 => VideoRange.Limited,
        _ => VideoRange.Unknown
    };

    internal static (int? Numerator, int? Denominator) UnpackRatio(ulong value)
    {
        var numerator = (uint)(value >> 32);
        var denominator = (uint)(value & uint.MaxValue);
        return numerator <= int.MaxValue && denominator <= int.MaxValue
            ? ((int)numerator, (int)denominator)
            : (null, null);
    }

    internal static (string Codec, string PixelFormat, int? BitDepth) DescribeVideoSubtype(Guid subtype)
    {
        if (subtype == FourCc("H264")) return ("H.264", "unknown", null);
        if (subtype == FourCc("H265") || subtype == FourCc("HEVC") || subtype == FourCc("HEVS")) return ("HEVC", "unknown", null);
        if (subtype == FourCc("AV01")) return ("AV1", "unknown", null);
        if (subtype == FourCc("VP90")) return ("VP9", "unknown", null);
        if (subtype == FourCc("P010")) return ("uncompressed", "P010", 10);
        if (subtype == FourCc("P016")) return ("uncompressed", "P016", 16);
        if (subtype == FourCc("NV12")) return ("uncompressed", "NV12", 8);
        return ("unknown", "unknown", null);
    }

    internal static string DescribeAudioSubtype(Guid subtype)
    {
        if (subtype == WaveFormat(0x0001)) return "PCM";
        if (subtype == WaveFormat(0x0003)) return "IEEE float";
        if (subtype == WaveFormat(0x0055)) return "MP3";
        if (subtype == WaveFormat(0x1610)) return "AAC";
        return "unknown";
    }

    internal static Guid FourCc(string value)
    {
        if (value.Length != 4 || value.Any(static character => character > byte.MaxValue))
        {
            throw new ArgumentException("A FourCC must contain exactly four single-byte characters.", nameof(value));
        }

        var data1 = (uint)value[0]
            | ((uint)value[1] << 8)
            | ((uint)value[2] << 16)
            | ((uint)value[3] << 24);
        return new Guid((int)data1, 0, 0x0010, 0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71);
    }

    private static Guid WaveFormat(uint formatTag) =>
        new((int)formatTag, 0, 0x0010, 0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71);
}
