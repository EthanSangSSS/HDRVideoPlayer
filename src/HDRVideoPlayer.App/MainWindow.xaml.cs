using HDRVideoPlayer.Core.Diagnostics;
using HDRVideoPlayer.Core.Metadata;
using HDRVideoPlayer.Core.Metadata.MediaFoundation;
using Microsoft.UI.Xaml;
using Windows.Storage.Pickers;
using WinRT.Interop;

namespace HDRVideoPlayer.App;

public sealed partial class MainWindow : Window
{
    private readonly IMediaProbe _probe = new MediaFoundationMediaProbe(new ExtensionHeuristicMediaProbe());

    public MainWindow()
    {
        InitializeComponent();
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

        var asset = _probe.Probe(file.Path);
        var report = DiagnosticReportFactory.Create(asset);

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

        DiagnosticsText.Text = string.Join(Environment.NewLine, lines);
    }
}
