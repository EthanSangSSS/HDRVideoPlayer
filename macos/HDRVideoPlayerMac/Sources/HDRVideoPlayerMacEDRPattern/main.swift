import AppKit
import HDRVideoPlayerMacCore
import HDRVideoPlayerMacMetal
import MetalKit

@MainActor
final class EDRPatternAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let configuration = MacEDRTestPatternConfiguration.reference
    private let metalView = MTKView()
    private let diagnosticsTextView = NSTextView()
    private let statusLabel = NSTextField(labelWithString: "Initializing Metal renderer")

    private var window: NSWindow?
    private var renderer: MacEDRMetalRenderer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1_180, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "HDRVideoPlayer Metal EDR Test Pattern"
        window.center()
        window.delegate = self
        window.contentMinSize = NSSize(width: 960, height: 560)
        window.contentView = makeContentView()
        window.makeKeyAndOrderFront(nil)
        self.window = window

        configureRenderer()
        updateDiagnostics()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
    }

    func windowDidChangeScreen(_ notification: Notification) {
        updateDiagnostics()
        metalView.setNeedsDisplay(metalView.bounds)
    }

    private func makeContentView() -> NSView {
        let root = NSView()

        let title = NSTextField(labelWithString: "Metal EDR Static Test Pattern")
        title.font = .systemFont(ofSize: 18, weight: .semibold)

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        let refreshButton = NSButton(
            image: NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh diagnostics")
                ?? NSImage(),
            target: self,
            action: #selector(refresh)
        )
        refreshButton.bezelStyle = .texturedRounded
        refreshButton.toolTip = "Refresh display diagnostics"
        refreshButton.setAccessibilityLabel("Refresh display diagnostics")

        let header = NSStackView(views: [title, statusLabel, NSView(), refreshButton])
        header.translatesAutoresizingMaskIntoConstraints = false
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 12

        let splitView = NSSplitView()
        splitView.translatesAutoresizingMaskIntoConstraints = false
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.addArrangedSubview(makePatternPane())
        splitView.addArrangedSubview(makeDiagnosticsPane())

        root.addSubview(header)
        root.addSubview(splitView)
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
            header.topAnchor.constraint(equalTo: root.topAnchor, constant: 12),
            header.heightAnchor.constraint(equalToConstant: 32),
            splitView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            splitView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            splitView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        return root
    }

    private func makePatternPane() -> NSView {
        let pane = NSView()
        pane.translatesAutoresizingMaskIntoConstraints = false

        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.wantsLayer = true
        metalView.layer?.backgroundColor = NSColor.black.cgColor

        let legend = NSGridView(views: legendRows())
        legend.translatesAutoresizingMaskIntoConstraints = false
        legend.rowSpacing = 6
        legend.columnSpacing = 12
        legend.xPlacement = .fill

        pane.addSubview(metalView)
        pane.addSubview(legend)
        NSLayoutConstraint.activate([
            pane.widthAnchor.constraint(greaterThanOrEqualToConstant: 600),
            metalView.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 16),
            metalView.trailingAnchor.constraint(equalTo: pane.trailingAnchor, constant: -16),
            metalView.topAnchor.constraint(equalTo: pane.topAnchor, constant: 16),
            metalView.heightAnchor.constraint(greaterThanOrEqualToConstant: 400),
            legend.leadingAnchor.constraint(equalTo: metalView.leadingAnchor),
            legend.trailingAnchor.constraint(equalTo: metalView.trailingAnchor),
            legend.topAnchor.constraint(equalTo: metalView.bottomAnchor, constant: 12),
            legend.bottomAnchor.constraint(lessThanOrEqualTo: pane.bottomAnchor, constant: -16)
        ])
        return pane
    }

    private func legendRows() -> [[NSView]] {
        let labels = configuration.colorStops.map { stop -> NSView in
            let components = stop.label.split(separator: " ")
            let value = components.last.map(String.init) ?? stop.label
            let name = components.dropLast().joined(separator: " ")
            let label = NSTextField(labelWithString: "\(name)\n\(value)")
            label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
            label.alignment = .center
            label.lineBreakMode = .byTruncatingTail
            label.maximumNumberOfLines = 2
            return label
        }
        return [labels]
    }

    private func makeDiagnosticsPane() -> NSView {
        let pane = NSView()
        pane.translatesAutoresizingMaskIntoConstraints = false

        diagnosticsTextView.isEditable = false
        diagnosticsTextView.isSelectable = true
        diagnosticsTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        diagnosticsTextView.textContainerInset = NSSize(width: 12, height: 12)
        diagnosticsTextView.minSize = .zero
        diagnosticsTextView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        diagnosticsTextView.isVerticallyResizable = true
        diagnosticsTextView.isHorizontallyResizable = false
        diagnosticsTextView.autoresizingMask = [.width]
        diagnosticsTextView.textContainer?.widthTracksTextView = true

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = diagnosticsTextView
        pane.addSubview(scrollView)

        NSLayoutConstraint.activate([
            pane.widthAnchor.constraint(greaterThanOrEqualToConstant: 330),
            scrollView.leadingAnchor.constraint(equalTo: pane.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: pane.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: pane.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: pane.bottomAnchor)
        ])
        return pane
    }

    private func configureRenderer() {
        do {
            renderer = try MacEDRMetalRenderer(view: metalView, configuration: configuration)
            statusLabel.stringValue = "Static renderer ready"
            metalView.draw()
        } catch {
            renderer = nil
            statusLabel.stringValue = "Renderer failed"
            diagnosticsTextView.string = "Renderer error:\n- \(error.localizedDescription)"
        }
    }

    @objc
    private func refresh() {
        updateDiagnostics()
        metalView.setNeedsDisplay(metalView.bounds)
    }

    @objc
    private func screenParametersChanged() {
        updateDiagnostics()
        metalView.setNeedsDisplay(metalView.bounds)
    }

    private func updateDiagnostics() {
        guard renderer != nil else {
            return
        }
        let display = MacDisplayDiagnostics.current(screen: window?.screen ?? NSScreen.main)
        let report = MacEDRTestPatternReportFactory.make(configuration: configuration, display: display)
        diagnosticsTextView.string = [
            section("Renderer facts", report.rendererFacts),
            section("Display / EDR facts", report.displayFacts),
            section("Unknowns", report.unknowns),
            section("Limitations", report.limitations),
            section("Presentation / rendering claim", [
                "Path: \(report.presentationClaim.path.rawValue)",
                "Accuracy: \(report.presentationClaim.accuracy.rawValue)",
                report.presentationClaim.limitation
            ])
        ].joined(separator: "\n\n")
    }

    private func section(_ title: String, _ values: [String]) -> String {
        let body = values.map { "- \($0)" }.joined(separator: "\n")
        return "\(title):\n\(body)"
    }
}

MainActor.assumeIsolated {
    let application = NSApplication.shared
    let delegate = EDRPatternAppDelegate()
    application.setActivationPolicy(.regular)
    application.delegate = delegate
    application.run()
}
