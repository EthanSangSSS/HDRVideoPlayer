using HDRVideoPlayer.Core.Media;
using HDRVideoPlayer.Core.Metadata.MediaFoundation;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace HDRVideoPlayer.Core.Tests;

[TestClass]
public sealed class MediaFoundationMetadataMapperTests
{
    [TestMethod]
    public void MapTransfer_MapsHdrTransferFunctions()
    {
        Assert.AreEqual(HdrTransfer.Pq, MediaFoundationMetadataMapper.MapTransfer(15));
        Assert.AreEqual(HdrTransfer.Hlg, MediaFoundationMetadataMapper.MapTransfer(16));
        Assert.AreEqual(HdrTransfer.Unknown, MediaFoundationMetadataMapper.MapTransfer(0));
    }

    [TestMethod]
    public void MapColorAttributes_MapsKnownValues()
    {
        Assert.AreEqual(ColorPrimaries.Bt2020, MediaFoundationMetadataMapper.MapPrimaries(9));
        Assert.AreEqual(MatrixCoefficients.Bt2020NonConstantLuminance, MediaFoundationMetadataMapper.MapMatrix(4));
        Assert.AreEqual(VideoRange.Limited, MediaFoundationMetadataMapper.MapRange(2));
    }

    [TestMethod]
    public void DescribeVideoSubtype_MapsHevcAndP010()
    {
        var hevc = MediaFoundationMetadataMapper.DescribeVideoSubtype(
            MediaFoundationMetadataMapper.FourCc("HEVC"));
        var p010 = MediaFoundationMetadataMapper.DescribeVideoSubtype(
            MediaFoundationMetadataMapper.FourCc("P010"));

        Assert.AreEqual("HEVC", hevc.Codec);
        Assert.AreEqual("P010", p010.PixelFormat);
        Assert.AreEqual(10, p010.BitDepth);
    }

    [TestMethod]
    public void UnpackRatio_ReturnsNumeratorAndDenominator()
    {
        var packed = ((ulong)24000 << 32) | 1001;

        var ratio = MediaFoundationMetadataMapper.UnpackRatio(packed);

        Assert.AreEqual(24000, ratio.Numerator);
        Assert.AreEqual(1001, ratio.Denominator);
    }
}
