using HDRVideoPlayer.Core.Media;

namespace HDRVideoPlayer.Core.Metadata;

public interface IMediaProbe
{
    MediaAsset Probe(string filePath);
}
