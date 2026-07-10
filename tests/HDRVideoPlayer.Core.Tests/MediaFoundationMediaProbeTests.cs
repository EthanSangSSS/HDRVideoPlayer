using System.Runtime.Versioning;
using HDRVideoPlayer.Core.Metadata;
using HDRVideoPlayer.Core.Metadata.MediaFoundation;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace HDRVideoPlayer.Core.Tests;

[TestClass]
public sealed class MediaFoundationMediaProbeTests
{
    [TestMethod]
    public void Probe_MissingFile_UsesBoundedFallback()
    {
        var probe = new MediaFoundationMediaProbe(new ExtensionHeuristicMediaProbe());

        var asset = probe.Probe(@"C:\missing\sample.mp4");

        Assert.AreEqual(ProbeConfidence.Heuristic, asset.ProbeEvidence.Confidence);
        Assert.AreEqual(0, asset.VideoStreams.Count);
        StringAssert.Contains(asset.ProbeEvidence.Limitation, "Media Foundation");
    }

    [TestMethod]
    [SupportedOSPlatform("windows")]
    public void Probe_GeneratedWaveFile_ReadsAudioStreamMetadataOnWindows()
    {
        if (!OperatingSystem.IsWindows())
        {
            Assert.Inconclusive("Media Foundation integration test requires Windows.");
        }

        var filePath = Path.Combine(Path.GetTempPath(), $"hdrvideoplayer-{Guid.NewGuid():N}.wav");
        try
        {
            WriteMinimalWaveFile(filePath);
            var probe = new MediaFoundationMediaProbe(new ExtensionHeuristicMediaProbe());

            var asset = probe.Probe(filePath);

            Assert.AreEqual(ProbeConfidence.ParsedMetadata, asset.ProbeEvidence.Confidence);
            Assert.AreEqual(1, asset.AudioStreams.Count);
            Assert.AreEqual("PCM", asset.AudioStreams[0].Codec);
            Assert.AreEqual(1, asset.AudioStreams[0].Channels);
            Assert.AreEqual(8000, asset.AudioStreams[0].SampleRate);
        }
        finally
        {
            File.Delete(filePath);
        }
    }

    private static void WriteMinimalWaveFile(string filePath)
    {
        const short channels = 1;
        const int sampleRate = 8000;
        const short bitsPerSample = 16;
        var samples = new short[80];
        var dataLength = samples.Length * sizeof(short);

        using var stream = File.Create(filePath);
        using var writer = new BinaryWriter(stream);
        writer.Write("RIFF"u8);
        writer.Write(36 + dataLength);
        writer.Write("WAVE"u8);
        writer.Write("fmt "u8);
        writer.Write(16);
        writer.Write((short)1);
        writer.Write(channels);
        writer.Write(sampleRate);
        writer.Write(sampleRate * channels * bitsPerSample / 8);
        writer.Write((short)(channels * bitsPerSample / 8));
        writer.Write(bitsPerSample);
        writer.Write("data"u8);
        writer.Write(dataLength);
        foreach (var sample in samples)
        {
            writer.Write(sample);
        }
    }
}
