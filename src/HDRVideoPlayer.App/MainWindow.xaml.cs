using HDRVideoPlayer.Core.Diagnostics;
using HDRVideoPlayer.Core.Metadata;
using Microsoft.UI.Xaml;
using Windows.Storage.Pickers;
using WinRT.Interop;

namespace HDRVideoPlayer.App;

public sealed partial class MainWindow : Window
{
    private readonly IMediaProbe _probe = new ExtensionHeuristicMediaProbe();

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

        DiagnosticsText.Text = string.Join(
            Environment.NewLine,
            new[]
            {
                "Facts:",
                ..report.Facts.Select(static f => $"- {f}"),
                "",
                "Limitations:",
                ..report.Limitations.Select(static l => $"- {l}"),
                "",
                "Next tests:",
                ..report.NextTests.Select(static n => $"- {n}")
            });
    }
}
