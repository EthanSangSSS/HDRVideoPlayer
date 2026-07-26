import Foundation

public struct MacDiagnosticReport: Equatable, Sendable {
    public var facts: [String]
    public var inferredFacts: [String]
    public var unknowns: [String]
    public var limitations: [String]
    public var nextTests: [String]

    public init(
        facts: [String],
        inferredFacts: [String],
        unknowns: [String],
        limitations: [String],
        nextTests: [String]
    ) {
        self.facts = facts
        self.inferredFacts = inferredFacts
        self.unknowns = unknowns
        self.limitations = limitations
        self.nextTests = nextTests
    }
}

public enum MacDiagnosticReportFactory {
    public static func make(
        asset: MacMediaAsset,
        display: MacDisplayDiagnostic? = nil
    ) -> MacDiagnosticReport {
        var facts = [
            "File: \(asset.fileName)",
            "Video track count: \(asset.videoStreams.count)",
            "Audio track count: \(asset.audioStreams.count)",
            "Probe confidence: \(asset.probeEvidence.confidence.rawValue)"
        ]

        for stream in asset.videoStreams {
            appendKnown(&facts, label: "Video track \(stream.index) codec", value: stream.codec)
            appendKnown(&facts, label: "Video track \(stream.index) width", value: stream.width)
            appendKnown(&facts, label: "Video track \(stream.index) height", value: stream.height)
            appendKnown(&facts, label: "Video track \(stream.index) nominal frame rate", value: stream.nominalFrameRate)
            appendKnown(&facts, label: "Video track \(stream.index) bit-depth candidate", value: stream.bitDepthCandidate)
            appendKnown(&facts, label: "Video track \(stream.index) pixel format", value: stream.pixelFormat)
            appendKnown(&facts, label: "Video track \(stream.index) color primaries", value: stream.colorPrimaries.rawValue)
            appendKnown(&facts, label: "Video track \(stream.index) transfer function", value: stream.transferFunction.rawValue)
            appendKnown(&facts, label: "Video track \(stream.index) YCbCr matrix", value: stream.yCbCrMatrix.rawValue)
        }

        for stream in asset.audioStreams {
            appendKnown(&facts, label: "Audio track \(stream.index) codec", value: stream.codec)
            appendKnown(&facts, label: "Audio track \(stream.index) channels", value: stream.channels)
            appendKnown(&facts, label: "Audio track \(stream.index) sample rate", value: stream.sampleRate)
        }

        if let display {
            appendKnown(&facts, label: "Display", value: display.screenName ?? "unknown")
            appendKnown(
                &facts,
                label: "Maximum EDR color component value",
                value: display.maximumEDRColorComponentValue
            )
            facts.append("EDR appears available: \(display.isEDRAvailable)")
        }

        var inferredFacts: [String] = []
        if asset.probeEvidence.sources.contains(.fileExtension), asset.container != "unknown" {
            inferredFacts.append("Extension-based container candidate: \(asset.container)")
        }
        if asset.dolbyVision.markersDetected {
            inferredFacts.append(
                "Filename-only Dolby Vision marker candidate: \(asset.dolbyVision.profileCandidate.rawValue)"
            )
        }

        var unknowns = [
            "HDR10 mastering metadata is not parsed.",
            "MaxCLL and MaxFALL are not parsed.",
            "Dolby Vision RPU, profile, level, and base-layer compatibility are not parsed from the container.",
            "Presentation accuracy is unknown and unverified.",
            "The system-preview report does not inspect or validate the separate static Metal EDR test-pattern path."
        ]
        if asset.videoStreams.isEmpty {
            unknowns.append("Video track metadata is unavailable.")
        }
        if asset.hdrSignal.transfer == .unknown {
            unknowns.append("HDR transfer function is unavailable.")
        }
        if asset.hdrSignal.primaries == .unknown {
            unknowns.append("Color primaries are unavailable.")
        }
        if asset.hdrSignal.matrix == .unknown {
            unknowns.append("YCbCr matrix is unavailable.")
        }

        var limitations = asset.hdrSignal.limitations
        limitations.append(asset.dolbyVision.limitation)
        limitations.append(asset.probeEvidence.limitation)
        limitations.append(asset.presentationClaim.limitation)
        if let display {
            limitations.append(display.limitation)
        }

        return MacDiagnosticReport(
            facts: facts,
            inferredFacts: inferredFacts,
            unknowns: unknowns,
            limitations: unique(limitations),
            nextTests: [
                "Run local macOS playback validation with authorized, uncommitted fixtures.",
                "Compare AVFoundation metadata with known-good file metadata.",
                "Record EDR output observations separately from playback readiness.",
                "Validate the separate static Metal EDR test pattern on an EDR-capable display before any video-frame work.",
                "Evaluate a future VideoToolbox, CVPixelBuffer, and Metal frame path separately."
            ]
        )
    }

    private static func appendKnown<T>(_ facts: inout [String], label: String, value: T?) {
        if let value {
            facts.append("\(label): \(value)")
        }
    }

    private static func appendKnown(_ facts: inout [String], label: String, value: String) {
        guard !value.isEmpty, value != "unknown" else {
            return
        }
        facts.append("\(label): \(value)")
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}
