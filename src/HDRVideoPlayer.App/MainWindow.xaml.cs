using HDRVideoPlayer.Core.Diagnostics;
using HDRVideoPlayer.Core.Media;
using HDRVideoPlayer.Core.Metadata;
using HDRVideoPlayer.Core.Metadata.MediaFoundation;
using Microsoft.UI.Xaml;
using Windows.Media.Core;
using Windows.Media.Playback;
using Windows.Storage.Pickers;
using WinRT.Interop;

namespace HDRVideoPlayer.App;

public sealed partial class MainWindow : Window
{
    private readonly IMediaProbe _probe = new MediaFoundationMediaProbe(new ExtensionHeuristicMediaProbe());
    private readonly MediaPlayer _mediaPlayer = new();
    private MediaSource? _mediaSource;

    public MainWindow()
    {
        InitializeComponent();
        Player.SetMediaPlayer(_mediaPlayer);
        _mediaPlayer.MediaOpened += MediaPlayer_MediaOpened;
        _mediaPlayer.MediaFailed += MediaPlayer_MediaFailed;
        Closed += MainWindow_Closed;
    }

    private async void OpenVideo_Click(object sender, RoutedEventArgs e)
    {
        var picker = new FileOpenPicker();
        InitializeWithWindow.Initialize(picker, WindowNative.GetWindowHandle(this));

        picker.FileTypeFilter.Add(".mp4");
        picker.FileTypeFilter.Add(".mov");
        picker.FileTypeFilter.Add(".m4v");
        picker.FileTypeFilter.Add(".mkv");

        var file = await picker.PickSingleFileAsync();
        if (file is null)
        {
            return;
        }

        ResetMediaSource();
        SetPlaybackState(SystemPlaybackState.Loading, "Loading through Windows system media.");

        var asset = _probe.Probe(file.Path) with
        {
            PlaybackPath = new PlaybackPath(
                PlaybackPathKind.SystemMedia,
                PresentationPathKind.Unknown,
                "Windows MediaPlayerElement",
                "System playback is wired as a preview. Successful media opening does not validate HDR or Dolby Vision presentation accuracy.")
        };
        var report = DiagnosticReportFactory.Create(asset);
        DiagnosticsText.Text = FormatMetadataReport(report);
        PresentationClaimText.Text =
            $"Presentation path: {asset.PlaybackPath.Presentation}. Unknown and unverified; no custom HDR or Dolby Vision rendering accuracy claim.";

        try
        {
            _mediaSource = MediaSource.CreateFromStorageFile(file);
            Player.Source = _mediaSource;
        }
        catch (Exception exception)
        {
            ResetMediaSource();
            SetPlaybackState(SystemPlaybackState.Failed, $"System media source creation failed ({exception.GetType().Name}).");
        }
    }

    private static string FormatMetadataReport(DiagnosticReport report)
    {
        var lines = new List<string> { "Facts:" };
        lines.AddRange(report.Facts.Select(static f => $"- {f}"));
        lines.Add("");
        lines.Add("Inferred facts:");
        lines.AddRange(report.InferredFacts.DefaultIfEmpty("none").Select(static f => $"- {f}"));
        lines.Add("");
        lines.Add("Unknowns:");
        lines.AddRange(report.Unknowns.Select(static u => $"- {u}"));
        lines.Add("");
        lines.Add("Limitations:");
        lines.AddRange(report.Limitations.Select(static l => $"- {l}"));
        lines.Add("");
        lines.Add("Next tests:");
        lines.AddRange(report.NextTests.Select(static n => $"- {n}"));

        return string.Join(Environment.NewLine, lines);
    }

    private void MediaPlayer_MediaOpened(MediaPlayer sender, object args)
    {
        _ = DispatcherQueue.TryEnqueue(() =>
            SetPlaybackState(
                SystemPlaybackState.Ready,
                "Ready. Windows system media opened the source; playback and presentation accuracy remain separate claims."));
    }

    private void MediaPlayer_MediaFailed(MediaPlayer sender, MediaPlayerFailedEventArgs args)
    {
        var error = args.Error.ToString();
        _ = DispatcherQueue.TryEnqueue(() =>
            SetPlaybackState(SystemPlaybackState.Failed, $"Windows system media failed to open the source ({error})."));
    }

    private void SetPlaybackState(SystemPlaybackState state, string message)
    {
        PlaybackStatusText.Text = $"{state}: {message}";
        SystemPlaybackText.Text =
            $"State: {state}. Path: {PlaybackPathKind.SystemMedia}. {message}";

        PlaybackProgress.IsActive = state == SystemPlaybackState.Loading;
        PlaybackProgress.Visibility = state == SystemPlaybackState.Loading
            ? Visibility.Visible
            : Visibility.Collapsed;
        PlaybackOverlay.Visibility = state == SystemPlaybackState.Ready
            ? Visibility.Collapsed
            : Visibility.Visible;
        PlaybackOverlayText.Text = message;
    }

    private void ResetMediaSource()
    {
        Player.Source = null;
        _mediaSource?.Dispose();
        _mediaSource = null;
    }

    private void MainWindow_Closed(object sender, WindowEventArgs args)
    {
        _mediaPlayer.MediaOpened -= MediaPlayer_MediaOpened;
        _mediaPlayer.MediaFailed -= MediaPlayer_MediaFailed;
        ResetMediaSource();
        Player.SetMediaPlayer(null);
        _mediaPlayer.Dispose();
    }

    private enum SystemPlaybackState
    {
        Idle,
        Loading,
        Ready,
        Failed
    }
}
