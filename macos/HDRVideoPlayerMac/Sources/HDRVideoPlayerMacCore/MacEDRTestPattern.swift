import Foundation

public struct MacEDRColorStop: Equatable, Sendable {
    public var label: String
    public var red: Float
    public var green: Float
    public var blue: Float

    public init(label: String, red: Float, green: Float, blue: Float) {
        self.label = label
        self.red = red
        self.green = green
        self.blue = blue
    }

    public var maximumComponent: Float {
        max(red, green, blue)
    }
}

public struct MacEDRTestPatternConfiguration: Equatable, Sendable {
    public var pixelFormatName: String
    public var colorSpaceName: String
    public var requestsExtendedDynamicRange: Bool
    public var colorStops: [MacEDRColorStop]

    public init(
        pixelFormatName: String,
        colorSpaceName: String,
        requestsExtendedDynamicRange: Bool,
        colorStops: [MacEDRColorStop]
    ) {
        self.pixelFormatName = pixelFormatName
        self.colorSpaceName = colorSpaceName
        self.requestsExtendedDynamicRange = requestsExtendedDynamicRange
        self.colorStops = colorStops
    }

    public static let reference = MacEDRTestPatternConfiguration(
        pixelFormatName: "rgba16Float",
        colorSpaceName: "extendedLinearSRGB",
        requestsExtendedDynamicRange: true,
        colorStops: [
            MacEDRColorStop(label: "Black 0.00", red: 0, green: 0, blue: 0),
            MacEDRColorStop(label: "Gray 0.18", red: 0.18, green: 0.18, blue: 0.18),
            MacEDRColorStop(label: "SDR white 1.00", red: 1, green: 1, blue: 1),
            MacEDRColorStop(label: "EDR white 2.00", red: 2, green: 2, blue: 2),
            MacEDRColorStop(label: "EDR white 4.00", red: 4, green: 4, blue: 4),
            MacEDRColorStop(label: "Red 2.00", red: 2, green: 0, blue: 0),
            MacEDRColorStop(label: "Green 2.00", red: 0, green: 2, blue: 0),
            MacEDRColorStop(label: "Blue 2.00", red: 0, green: 0, blue: 2)
        ]
    )

    public var maximumSubmittedComponent: Float {
        colorStops.map(\.maximumComponent).max() ?? 0
    }

    public var acceptsVideoFrames: Bool {
        false
    }
}

public struct MacEDRTestPatternReport: Equatable, Sendable {
    public var rendererFacts: [String]
    public var displayFacts: [String]
    public var unknowns: [String]
    public var limitations: [String]
    public var presentationClaim: MacPresentationClaim

    public init(
        rendererFacts: [String],
        displayFacts: [String],
        unknowns: [String],
        limitations: [String],
        presentationClaim: MacPresentationClaim
    ) {
        self.rendererFacts = rendererFacts
        self.displayFacts = displayFacts
        self.unknowns = unknowns
        self.limitations = limitations
        self.presentationClaim = presentationClaim
    }
}

public enum MacEDRTestPatternReportFactory {
    public static func make(
        configuration: MacEDRTestPatternConfiguration = .reference,
        display: MacDisplayDiagnostic
    ) -> MacEDRTestPatternReport {
        let currentEDR = display.maximumCurrentEDRColorComponentValue
            .map { String(format: "%.2f", $0) } ?? "unknown"
        let potentialEDR = display.maximumPotentialEDRColorComponentValue
            .map { String(format: "%.2f", $0) } ?? "unknown"
        let referenceEDR = display.maximumReferenceEDRColorComponentValue
            .map { String(format: "%.2f", $0) } ?? "unknown"

        return MacEDRTestPatternReport(
            rendererFacts: [
                "Presentation path: \(MacPresentationPath.metalEDRTestPattern.rawValue)",
                "Drawable pixel format: \(configuration.pixelFormatName)",
                "Drawable color space: \(configuration.colorSpaceName)",
                "EDR content requested: \(configuration.requestsExtendedDynamicRange)",
                String(format: "Maximum submitted component: %.2f", configuration.maximumSubmittedComponent),
                "Static color stops: \(configuration.colorStops.count)",
                "Decoded video frames accepted: \(configuration.acceptsVideoFrames)"
            ],
            displayFacts: [
                "Screen: \(display.screenName ?? "unknown")",
                "Display supports EDR: \(display.supportsEDR)",
                "Current EDR headroom available: \(display.hasCurrentEDRHeadroom)",
                "Current maximum EDR component: \(currentEDR)",
                "Potential maximum EDR component: \(potentialEDR)",
                "Reference maximum EDR component: \(referenceEDR)"
            ],
            unknowns: [
                "Visible luminance and clipping have not been measured.",
                "Colorimetric accuracy is unknown and unverified.",
                "HDR10, HLG, and Dolby Vision video presentation are not exercised by this static pattern."
            ],
            limitations: [
                display.limitation,
                "Values above 1.0 are submitted as extended-linear-sRGB test pixels only; display output depends on current screen headroom and system composition.",
                "No AVPlayer, VideoToolbox, CVPixelBuffer, decoded video frame, dynamic metadata, or Dolby Vision renderer is connected."
            ],
            presentationClaim: .metalEDRTestPattern
        )
    }
}

public extension MacPresentationClaim {
    static let metalEDRTestPattern = MacPresentationClaim(
        path: .metalEDRTestPattern,
        accuracy: .unverified,
        limitation: "Unknown and unverified. Static Metal EDR test pixels do not establish HDR or Dolby Vision video rendering accuracy."
    )
}
