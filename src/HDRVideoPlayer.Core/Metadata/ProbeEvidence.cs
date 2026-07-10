namespace HDRVideoPlayer.Core.Metadata;

public sealed record ProbeEvidence(
    ProbeConfidence Confidence,
    IReadOnlyList<ProbeEvidenceSource> Sources,
    string Limitation
);

public enum ProbeConfidence
{
    Unknown,
    Heuristic,
    ParsedMetadata
}

public enum ProbeEvidenceSource
{
    None,
    FileExtension,
    FileNameMarker,
    ContainerMetadata
}
