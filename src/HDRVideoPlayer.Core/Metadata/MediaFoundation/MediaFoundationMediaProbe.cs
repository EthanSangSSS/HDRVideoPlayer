using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using HDRVideoPlayer.Core.Media;

namespace HDRVideoPlayer.Core.Metadata.MediaFoundation;

public sealed class MediaFoundationMediaProbe : IMediaProbe
{
    private readonly IMediaProbe _fallback;

    public MediaFoundationMediaProbe(IMediaProbe? fallback = null)
    {
        _fallback = fallback ?? new ExtensionHeuristicMediaProbe();
    }

    public MediaAsset Probe(string filePath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(filePath);

        var fallbackAsset = _fallback.Probe(filePath);
        if (!OperatingSystem.IsWindows())
        {
            return WithFallbackLimitation(fallbackAsset, "Media Foundation probing requires Windows.");
        }

        if (!File.Exists(filePath))
        {
            return WithFallbackLimitation(fallbackAsset, "Media Foundation probing requires an existing local file.");
        }

        try
        {
            return ProbeWithMediaFoundation(filePath, fallbackAsset);
        }
        catch (Exception exception) when (exception is COMException
            or InvalidCastException
            or DllNotFoundException
            or EntryPointNotFoundException
            or PlatformNotSupportedException)
        {
            return WithFallbackLimitation(fallbackAsset, $"Media Foundation probe failed: {exception.Message}");
        }
    }

    [SupportedOSPlatform("windows")]
    private static MediaAsset ProbeWithMediaFoundation(string filePath, MediaAsset fallbackAsset)
    {
        var comResult = MediaFoundationInterop.CoInitializeEx(IntPtr.Zero, MediaFoundationInterop.CoInitMultithreaded);
        var shouldUninitializeCom = comResult >= 0;
        if (comResult < 0 && comResult != MediaFoundationInterop.RpcEChangedMode)
        {
            Marshal.ThrowExceptionForHR(comResult);
        }

        IMFSourceResolver? resolver = null;
        IMFMediaSource? source = null;
        IMFPresentationDescriptor? presentation = null;
        var mediaFoundationStarted = false;

        try
        {
            ThrowIfFailed(MediaFoundationInterop.MFStartup(
                MediaFoundationInterop.MfVersion,
                MediaFoundationInterop.MfStartupNoSocket));
            mediaFoundationStarted = true;

            ThrowIfFailed(MediaFoundationInterop.MFCreateSourceResolver(out resolver));
            ThrowIfFailed(resolver.CreateObjectFromURL(
                filePath,
                MediaFoundationInterop.MfResolutionMediaSource,
                IntPtr.Zero,
                out var objectType,
                out var sourceObject));

            if (objectType != MfObjectType.MediaSource || sourceObject is not IMFMediaSource mediaSource)
            {
                ReleaseComObject(sourceObject);
                throw new COMException("The source resolver did not return a media source.");
            }

            source = mediaSource;
            ThrowIfFailed(source.CreatePresentationDescriptor(out presentation));
            ThrowIfFailed(presentation.GetStreamDescriptorCount(out var streamCount));

            var videos = new List<VideoStreamInfo>();
            var audios = new List<AudioStreamInfo>();
            HdrSignal? hdrSignal = null;

            for (uint index = 0; index < streamCount; index++)
            {
                ReadStream(presentation, index, videos, audios, ref hdrSignal);
            }

            return fallbackAsset with
            {
                VideoStreams = videos,
                AudioStreams = audios,
                HdrSignal = hdrSignal ?? HdrSignal.Unknown("Media Foundation did not expose a video stream with HDR attributes."),
                ProbeEvidence = new ProbeEvidence(
                    ProbeConfidence.ParsedMetadata,
                    fallbackAsset.DolbyVision.MarkersDetected
                        ? [ProbeEvidenceSource.FileExtension, ProbeEvidenceSource.ContainerMetadata, ProbeEvidenceSource.FileNameMarker]
                        : [ProbeEvidenceSource.FileExtension, ProbeEvidenceSource.ContainerMetadata],
                    "Media Foundation media-type attributes were read. Codec availability, mastering chromaticity coordinates, and Dolby Vision private metadata are not parsed or validated.")
            };
        }
        finally
        {
            if (source is not null)
            {
                _ = source.Shutdown();
            }

            ReleaseComObject(presentation);
            ReleaseComObject(source);
            ReleaseComObject(resolver);

            if (mediaFoundationStarted)
            {
                _ = MediaFoundationInterop.MFShutdown();
            }

            if (shouldUninitializeCom)
            {
                MediaFoundationInterop.CoUninitialize();
            }
        }
    }

    private static void ReadStream(
        IMFPresentationDescriptor presentation,
        uint index,
        ICollection<VideoStreamInfo> videos,
        ICollection<AudioStreamInfo> audios,
        ref HdrSignal? hdrSignal)
    {
        IMFStreamDescriptor? descriptor = null;
        IMFMediaTypeHandler? handler = null;
        IMFMediaType? mediaType = null;

        try
        {
            ThrowIfFailed(presentation.GetStreamDescriptorByIndex(index, out _, out descriptor));
            ThrowIfFailed(descriptor.GetMediaTypeHandler(out handler));
            ThrowIfFailed(handler.GetMajorType(out var majorType));

            var mediaTypeResult = handler.GetCurrentMediaType(out mediaType);
            if (mediaTypeResult < 0)
            {
                ThrowIfFailed(handler.GetMediaTypeByIndex(0, out mediaType));
            }

            if (majorType == MediaFoundationMetadataMapper.MediaTypeVideo)
            {
                videos.Add(CreateVideoStream(index, mediaType));
                hdrSignal ??= CreateHdrSignal(mediaType);
            }
            else if (majorType == MediaFoundationMetadataMapper.MediaTypeAudio)
            {
                audios.Add(CreateAudioStream(index, mediaType));
            }
        }
        finally
        {
            ReleaseComObject(mediaType);
            ReleaseComObject(handler);
            ReleaseComObject(descriptor);
        }
    }

    private static VideoStreamInfo CreateVideoStream(uint index, IMFMediaType mediaType)
    {
        var subtype = TryGetGuid(mediaType, MediaFoundationMetadataMapper.Subtype, out var subtypeValue)
            ? subtypeValue
            : Guid.Empty;
        var description = MediaFoundationMetadataMapper.DescribeVideoSubtype(subtype);

        int? width = null;
        int? height = null;
        if (TryGetUInt64(mediaType, MediaFoundationMetadataMapper.FrameSize, out var frameSize))
        {
            (width, height) = MediaFoundationMetadataMapper.UnpackRatio(frameSize);
        }

        double? frameRate = null;
        if (TryGetUInt64(mediaType, MediaFoundationMetadataMapper.FrameRate, out var frameRateValue))
        {
            var (numerator, denominator) = MediaFoundationMetadataMapper.UnpackRatio(frameRateValue);
            if (numerator.HasValue && denominator is > 0)
            {
                frameRate = (double)numerator.Value / denominator.Value;
            }
        }

        return new VideoStreamInfo(
            checked((int)index),
            description.Codec,
            width,
            height,
            frameRate,
            description.BitDepth,
            description.PixelFormat);
    }

    private static AudioStreamInfo CreateAudioStream(uint index, IMFMediaType mediaType)
    {
        var codec = TryGetGuid(mediaType, MediaFoundationMetadataMapper.Subtype, out var subtype)
            ? MediaFoundationMetadataMapper.DescribeAudioSubtype(subtype)
            : "unknown";
        var channels = TryGetUInt32(mediaType, MediaFoundationMetadataMapper.AudioChannels, out var channelValue)
            ? ToNullableInt(channelValue)
            : null;
        var sampleRate = TryGetUInt32(mediaType, MediaFoundationMetadataMapper.AudioSampleRate, out var sampleRateValue)
            ? ToNullableInt(sampleRateValue)
            : null;

        return new AudioStreamInfo(checked((int)index), codec, channels, sampleRate);
    }

    private static HdrSignal CreateHdrSignal(IMFMediaType mediaType)
    {
        var transfer = TryGetUInt32(mediaType, MediaFoundationMetadataMapper.TransferFunction, out var transferValue)
            ? MediaFoundationMetadataMapper.MapTransfer(transferValue)
            : HdrTransfer.Unknown;
        var primaries = TryGetUInt32(mediaType, MediaFoundationMetadataMapper.VideoPrimaries, out var primaryValue)
            ? MediaFoundationMetadataMapper.MapPrimaries(primaryValue)
            : ColorPrimaries.Unknown;
        var matrix = TryGetUInt32(mediaType, MediaFoundationMetadataMapper.YuvMatrix, out var matrixValue)
            ? MediaFoundationMetadataMapper.MapMatrix(matrixValue)
            : MatrixCoefficients.Unknown;
        var range = TryGetUInt32(mediaType, MediaFoundationMetadataMapper.VideoNominalRange, out var rangeValue)
            ? MediaFoundationMetadataMapper.MapRange(rangeValue)
            : VideoRange.Unknown;
        var maxCll = TryGetUInt32(mediaType, MediaFoundationMetadataMapper.MaxLuminanceLevel, out var maxCllValue)
            ? ToNullableInt(maxCllValue)
            : null;
        var maxFall = TryGetUInt32(mediaType, MediaFoundationMetadataMapper.MaxFrameAverageLuminanceLevel, out var maxFallValue)
            ? ToNullableInt(maxFallValue)
            : null;

        var masteringParts = new List<string>();
        if (TryGetUInt32(mediaType, MediaFoundationMetadataMapper.MinMasteringLuminance, out var minMastering))
        {
            masteringParts.Add($"min luminance={minMastering / 10000d:0.####} nits");
        }

        if (TryGetUInt32(mediaType, MediaFoundationMetadataMapper.MaxMasteringLuminance, out var maxMastering))
        {
            masteringParts.Add($"max luminance={maxMastering} nits");
        }

        var hasHdrAttributes = transfer is HdrTransfer.Pq or HdrTransfer.Hlg
            || primaries == ColorPrimaries.Bt2020
            || maxCll.HasValue
            || maxFall.HasValue
            || masteringParts.Count > 0;

        return new HdrSignal(
            transfer,
            primaries,
            matrix,
            null,
            maxCll,
            maxFall,
            string.Join(", ", masteringParts),
            range,
            hasHdrAttributes ? CapabilityState.DetectOnly : CapabilityState.NotStarted,
            hasHdrAttributes
                ? "HDR fields are Media Foundation metadata facts only. Rendering output has not been implemented or validated; mastering chromaticity coordinates are not parsed."
                : "Media Foundation exposed no HDR color or luminance attributes for the selected video stream.");
    }

    private static bool TryGetUInt32(IMFAttributes attributes, Guid key, out uint value) =>
        attributes.GetUINT32(key, out value) >= 0;

    private static bool TryGetUInt64(IMFAttributes attributes, Guid key, out ulong value) =>
        attributes.GetUINT64(key, out value) >= 0;

    private static bool TryGetGuid(IMFAttributes attributes, Guid key, out Guid value) =>
        attributes.GetGUID(key, out value) >= 0;

    private static int? ToNullableInt(uint value) => value <= int.MaxValue ? (int)value : null;

    private static MediaAsset WithFallbackLimitation(MediaAsset asset, string limitation) => asset with
    {
        ProbeEvidence = asset.ProbeEvidence with
        {
            Limitation = $"{asset.ProbeEvidence.Limitation} {limitation}"
        }
    };

    private static void ThrowIfFailed(int result)
    {
        if (result < 0)
        {
            Marshal.ThrowExceptionForHR(result);
        }
    }

    [SupportedOSPlatform("windows")]
    private static void ReleaseComObject(object? value)
    {
        if (value is not null && Marshal.IsComObject(value))
        {
            _ = Marshal.FinalReleaseComObject(value);
        }
    }
}
