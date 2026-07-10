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
        Assert.AreEqual(ProbeConfidence.Heuristic, asset.ProbeEvidence.Confidence);
        CollectionAssert.Contains(asset.ProbeEvidence.Sources.ToList(), ProbeEvidenceSource.FileExtension);
        Assert.IsFalse(asset.DolbyVision.MarkersDetected);
        Assert.AreEqual(DolbyVisionProfileCandidate.Unknown, asset.DolbyVision.ProfileCandidate);
    }

    [TestMethod]
    public void Probe_Mkv_ReturnsSupportedContainer()
    {
        var probe = new ExtensionHeuristicMediaProbe();

        var asset = probe.Probe(@"C:\media\sample.mkv");

        Assert.AreEqual("MKV", asset.Container);
        Assert.AreEqual(PlaybackPathKind.SystemMedia, asset.PlaybackPath.Kind);
    }

    [TestMethod]
    public void Probe_DolbyVisionFilenameMarker_ReturnsDetectOnlyCandidate()
    {
        var probe = new ExtensionHeuristicMediaProbe();

        var asset = probe.Probe(@"C:\media\movie_dovi_profile81.mp4");

        Assert.IsTrue(asset.DolbyVision.MarkersDetected);
        Assert.AreEqual(DolbyVisionProfileCandidate.Profile81, asset.DolbyVision.ProfileCandidate);
        Assert.AreEqual(CapabilityState.DetectOnly, asset.DolbyVision.State);
        CollectionAssert.Contains(asset.ProbeEvidence.Sources.ToList(), ProbeEvidenceSource.FileNameMarker);
        StringAssert.Contains(asset.DolbyVision.Limitation, "not implemented");
        StringAssert.Contains(asset.PlaybackPath.Limitation, "not yet wired");
    }

    [TestMethod]
    public void Probe_UnsupportedExtension_ReturnsUnsupported()
    {
        var probe = new ExtensionHeuristicMediaProbe();

        var asset = probe.Probe(@"C:\media\sample.txt");

        Assert.AreEqual("UNKNOWN", asset.Container);
        Assert.AreEqual(PlaybackPathKind.Unsupported, asset.PlaybackPath.Kind);
        Assert.AreEqual(ProbeConfidence.Unknown, asset.ProbeEvidence.Confidence);
    }
}
