import AppKit
import AVFoundation
import AVKit
import HDRVideoPlayerMacCore
import UniformTypeIdentifiers

private let boundedPresentationText =
    "Unknown and unverified. No custom Metal HDR or Dolby Vision rendering accuracy claim."

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let metadataProbe = MacMetadataProbe()
    private let playerView = AVPlayerView()
    private let metadataTextView = NSTextView()
    private let playbackStatusLabel = NSTextField(wrappingLabelWithString: "State: idle")
    private let displayDiagnosticsLabel = NSTextField(wrappingLabelWithString: "Display facts not loaded.")
    private let presentationClaimLabel = NSTextField(wrappingLabelWithString: boundedPresentationText)

    private var window: NSWindow?
    private var player: AVPlayer?
    private var playerItemObservation: NSKeyValueObservation?
    private var loadingTask: Task<Void, Never>?
    private var currentAsset: MacMediaAsset?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1_180, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "HDRVideoPlayer macOS Preview"
        window.center()
        window.delegate = self
        window.contentMinSize = NSSize(width: 900, height: 560)
        window.contentView = makeContentView()
        window.makeKeyAndOrderFront(nil)
        self.window = window

        updateDisplayDiagnostics()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        loadingTask?.cancel()
        playerItemObservation = nil
        player?.pause()
    }

    func windowDidChangeScreen(_ notification: Notification) {
        updateDisplayDiagnostics()
    }

    private func makeContentView() -> NSView {
        let root = NSView()

        let splitView = NSSplitView()
        splitView.translatesAutoresizingMaskIntoConstraints = false
        splitView.isVertical = true
        splitView.dividerStyle = .thin

        splitView.addArrangedSubview(makePlayerPane())
        splitView.addArrangedSubview(makeDiagnosticsPane())
        root.addSubview(splitView)

        NSLayoutConstraint.activate([
            splitView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            splitView.topAnchor.constraint(equalTo: root.topAnchor),
            splitView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])

        return root
    }

    private func makePlayerPane() -> NSView {
        let pane = NSView()
        pane.translatesAutoresizingMaskIntoConstraints = false

        let openButton = NSButton(title: "Open Video", target: self, action: #selector(openVideo))
        openButton.bezelStyle = .rounded

        let title = NSTextField(labelWithString: "macOS system-media preview")
        title.font = .systemFont(ofSize: 15, weight: .semibold)

        let header = NSStackView(views: [title, NSView(), openButton])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 12

        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.controlsStyle = .floating
        playerView.videoGravity = .resizeAspect
        playerView.wantsLayer = true
        playerView.layer?.backgroundColor = NSColor.black.cgColor

        let stack = NSStackView(views: [header, playerView])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        pane.addSubview(stack)

        NSLayoutConstraint.activate([
            pane.widthAnchor.constraint(greaterThanOrEqualToConstant: 520),
            stack.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: pane.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: pane.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: pane.bottomAnchor, constant: -16),
            header.widthAnchor.constraint(equalTo: stack.widthAnchor),
            playerView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            playerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 420)
        ])

        return pane
    }

    private func makeDiagnosticsPane() -> NSView {
        let pane = NSView()
        pane.translatesAutoresizingMaskIntoConstraints = false

        metadataTextView.isEditable = false
        metadataTextView.isSelectable = true
        metadataTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        metadataTextView.string = "Open a local file to inspect metadata facts."
        metadataTextView.textContainerInset = NSSize(width: 8, height: 8)
        metadataTextView.minSize = .zero
        metadataTextView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        metadataTextView.isVerticallyResizable = true
        metadataTextView.isHorizontallyResizable = false
        metadataTextView.autoresizingMask = [.width]
        metadataTextView.textContainer?.widthTracksTextView = true

        let metadataScrollView = NSScrollView()
        metadataScrollView.translatesAutoresizingMaskIntoConstraints = false
        metadataScrollView.hasVerticalScroller = true
        metadataScrollView.autohidesScrollers = true
        metadataScrollView.documentView = metadataTextView
        metadataScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260).isActive = true

        let sections = [
            makeSection(title: "Metadata facts", content: metadataScrollView),
            makeSection(title: "System playback path", content: playbackStatusLabel),
            makeSection(title: "Display / EDR diagnostics", content: displayDiagnosticsLabel),
            makeSection(title: "Presentation / rendering claim", content: presentationClaimLabel)
        ]
        let stack = NSStackView(views: sections)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        pane.addSubview(stack)

        NSLayoutConstraint.activate([
            pane.widthAnchor.constraint(greaterThanOrEqualToConstant: 400),
            stack.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: pane.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: pane.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: pane.bottomAnchor, constant: -16)
        ])
        NSLayoutConstraint.activate(sections.map { $0.widthAnchor.constraint(equalTo: stack.widthAnchor) })

        return pane
    }

    private func makeSection(title: String, content: NSView) -> NSBox {
        let box = NSBox()
        box.translatesAutoresizingMaskIntoConstraints = false
        box.title = title
        box.titlePosition = .atTop
        box.boxType = .primary

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(content)
        box.contentView = container

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            content.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])

        return box
    }

    @objc
    private func openVideo() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Open"
        panel.allowedContentTypes = ["mp4", "mov", "m4v", "mkv"].compactMap {
            UTType(filenameExtension: $0)
        }

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        beginLoading(url)
    }

    private func beginLoading(_ url: URL) {
        loadingTask?.cancel()
        playerItemObservation = nil
        player?.pause()
        player = nil
        playerView.player = nil
        currentAsset = nil
        metadataTextView.string = "Loading metadata facts for \(url.lastPathComponent)..."
        let containerNote = url.pathExtension.lowercased() == "mkv"
            ? " MKV support is system-dependent."
            : ""
        setPlaybackState(.loading, message: "Loading through AVPlayer system media.\(containerNote)")

        loadingTask = Task { @MainActor [weak self] in
            guard let self else { return }

            let probedAsset = await metadataProbe.probe(url)
            guard !Task.isCancelled else { return }

            currentAsset = probedAsset.withSystemPlaybackState(.loading)
            updateMetadataReport()

            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            self.player = player
            playerView.player = player
            observe(item)
        }
    }

    private func observe(_ item: AVPlayerItem) {
        playerItemObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.handlePlayerItemStatus(item)
            }
        }
    }

    private func handlePlayerItemStatus(_ item: AVPlayerItem) {
        switch item.status {
        case .unknown:
            setPlaybackState(.loading, message: "Waiting for AVPlayer item readiness.")
        case .readyToPlay:
            setPlaybackState(
                .ready,
                message: "AVPlayer accepted the source. Presentation accuracy remains unknown."
            )
        case .failed:
            let detail = item.error?.localizedDescription ?? "unknown error"
            setPlaybackState(.failed, message: "AVPlayer failed to open the source (\(detail)).")
        @unknown default:
            setPlaybackState(.failed, message: "AVPlayer returned an unknown item status.")
        }
    }

    private func setPlaybackState(_ state: MacSystemPlaybackState, message: String) {
        if let asset = currentAsset {
            currentAsset = asset.withSystemPlaybackState(state)
        }
        playbackStatusLabel.stringValue = "State: \(state.rawValue)\n\(message)"
        presentationClaimLabel.stringValue = boundedPresentationText
    }

    private func updateMetadataReport() {
        guard let currentAsset else {
            return
        }

        let display = MacDisplayDiagnostics.current(screen: window?.screen ?? NSScreen.main)
        let report = MacDiagnosticReportFactory.make(asset: currentAsset, display: display)
        metadataTextView.string = format(report)
    }

    private func updateDisplayDiagnostics() {
        let diagnostic = MacDisplayDiagnostics.current(screen: window?.screen ?? NSScreen.main)
        let currentEDR = diagnostic.maximumCurrentEDRColorComponentValue
            .map { String(format: "%.2f", $0) } ?? "unknown"
        let potentialEDR = diagnostic.maximumPotentialEDRColorComponentValue
            .map { String(format: "%.2f", $0) } ?? "unknown"
        let referenceEDR = diagnostic.maximumReferenceEDRColorComponentValue
            .map { String(format: "%.2f", $0) } ?? "unknown"
        displayDiagnosticsLabel.stringValue = [
            "Screen: \(diagnostic.screenName ?? "unknown")",
            "Display supports EDR: \(diagnostic.supportsEDR)",
            "Current EDR headroom available: \(diagnostic.hasCurrentEDRHeadroom)",
            "Current maximum EDR component: \(currentEDR)",
            "Potential maximum EDR component: \(potentialEDR)",
            "Reference maximum EDR component: \(referenceEDR)",
            diagnostic.limitation
        ].joined(separator: "\n")

        updateMetadataReport()
    }

    private func format(_ report: MacDiagnosticReport) -> String {
        [
            section("Facts", report.facts),
            section("Inferred facts", report.inferredFacts),
            section("Unknowns", report.unknowns),
            section("Limitations", report.limitations),
            section("Next tests", report.nextTests)
        ].joined(separator: "\n\n")
    }

    private func section(_ title: String, _ values: [String]) -> String {
        let body = values.isEmpty ? "- none" : values.map { "- \($0)" }.joined(separator: "\n")
        return "\(title):\n\(body)"
    }
}

MainActor.assumeIsolated {
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.setActivationPolicy(.regular)
    application.delegate = delegate
    application.run()
}
