using HDRVideoPlayer.Core.Diagnostics;
using HDRVideoPlayer.Core.Media;
using HDRVideoPlayer.Core.Metadata;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace HDRVideoPlayer.Core.Tests;

[TestClass]
public sealed class DiagnosticReportFactoryTests
{
    [TestMethod]
    public void Create_IncludesUnknownsLimitationsAndNextTests()
    {
        var asset = new ExtensionHeuristicMediaProbe().Probe(@"C:\media\sample.mp4");

        var report = DiagnosticReportFactory.Create(asset);

        Assert.IsTrue(report.Unknowns.Count > 0);
        Assert.IsTrue(report.Limitations.Count > 0);
        Assert.IsTrue(report.NextTests.Count > 0);
        Assert.IsTrue(report.Limitations.Any(static limitation =>
            limitation.Contains("metadata", StringComparison.OrdinalIgnoreCase)));
    }

    [TestMethod]
    public void Create_KeepsPlaybackAndPresentationOutOfMetadataFacts()
    {
        var asset = new ExtensionHeuristicMediaProbe().Probe(@"C:\media\sample.mp4");

        var report = DiagnosticReportFactory.Create(asset);

        Assert.IsFalse(report.Facts.Any(static fact => fact.StartsWith("Playback path:", StringComparison.Ordinal)));
        Assert.IsFalse(report.Facts.Any(static fact => fact.StartsWith("Presentation path:", StringComparison.Ordinal)));
        Assert.AreEqual(PresentationPathKind.Unknown, asset.PlaybackPath.Presentation);
        Assert.IsFalse(report.Limitations.Contains(asset.PlaybackPath.Limitation));
    }
}
