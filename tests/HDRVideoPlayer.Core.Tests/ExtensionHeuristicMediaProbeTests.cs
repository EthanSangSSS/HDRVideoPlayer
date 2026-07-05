using HDRVideoPlayer.Core.Media;
using HDRVideoPlayer.Core.Metadata;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace HDRVideoPlayer.Core.Tests;

[TestClass]
public sealed class ExtensionHeuristicMediaProbeTests
{
    [TestMethod]
    public void Probe_Mp4_ReturnsSystemMediaPlaceholder()
    {
        var probe = new ExtensionHeuristicMediaProbe();

        var asset = probe.Probe(@"C:\media\sample.mp4");

        Assert.AreEqual("sample.mp4", asset.FileName);
        Assert.AreEqual("MP4", asset.Container);
        Assert.AreEqual(PlaybackPathKind.SystemMedia, asset.PlaybackPath.Kind);
        Assert.AreEqual(CapabilityState.NotStarted, asset.HdrSignal.State);
        Assert.IsFalse(asset.DolbyVision.MarkersDetected);
    }

    [TestMethod]
    public void Probe_UnsupportedExtension_ReturnsUnsupported()
    {
        var probe = new ExtensionHeuristicMediaProbe();

        var asset = probe.Probe(@"C:\media\sample.txt");

        Assert.AreEqual("UNKNOWN", asset.Container);
        Assert.AreEqual(PlaybackPathKind.Unsupported, asset.PlaybackPath.Kind);
    }
}
