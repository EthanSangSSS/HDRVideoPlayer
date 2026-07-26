import Foundation

public enum MacLocalValidationCategory: String, Codable, CaseIterable, Sendable {
    case sdrH264MP4 = "sdr_h264_mp4"
    case hdr10HEVCMain10 = "hdr10_hevc_main10"
    case hlg
    case dolbyVisionProfile81Fallback = "dolby_vision_profile_8_1_fallback"
    case dolbyVisionProfile5Or7DetectOnly = "dolby_vision_profile_5_or_7_detect_only"
    case unsupportedOrMissingCodec = "unsupported_or_missing_codec"
}

public struct MacLocalValidationFixture: Codable, Equatable, Sendable {
    public var id: String
    public var category: MacLocalValidationCategory
    public var path: String
    public var notes: String?

    public init(
        id: String,
        category: MacLocalValidationCategory,
        path: String,
        notes: String? = nil
    ) {
        self.id = id
        self.category = category
        self.path = path
        self.notes = notes
    }
}

public enum MacLocalValidationManifestError: Error, Equatable, LocalizedError {
    case empty
    case missingValue(id: String, field: String)
    case duplicateID(String)
    case nonAbsolutePath(id: String)
    case missingCategories([MacLocalValidationCategory])

    public var errorDescription: String? {
        switch self {
        case .empty:
            return "Fixture manifest must contain at least one fixture."
        case let .missingValue(id, field):
            return "Fixture '\(id)' requires a non-empty '\(field)' value."
        case let .duplicateID(id):
            return "Fixture id '\(id)' is duplicated."
        case let .nonAbsolutePath(id):
            return "Fixture '\(id)' must use an absolute local path."
        case let .missingCategories(categories):
            return "Fixture manifest is missing required categories: \(categories.map(\.rawValue).joined(separator: ", "))."
        }
    }
}

public enum MacLocalValidationManifest {
    public static func decode(_ data: Data) throws -> [MacLocalValidationFixture] {
        let fixtures = try JSONDecoder().decode([MacLocalValidationFixture].self, from: data)
        try validate(fixtures)
        return fixtures
    }

    public static func validate(_ fixtures: [MacLocalValidationFixture]) throws {
        guard !fixtures.isEmpty else {
            throw MacLocalValidationManifestError.empty
        }

        var fixtureIDs = Set<String>()
        var presentCategories = Set<MacLocalValidationCategory>()

        for fixture in fixtures {
            let id = fixture.id.trimmingCharacters(in: .whitespacesAndNewlines)
            let path = fixture.path.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !id.isEmpty else {
                throw MacLocalValidationManifestError.missingValue(id: "unknown", field: "id")
            }
            guard !path.isEmpty else {
                throw MacLocalValidationManifestError.missingValue(id: id, field: "path")
            }
            guard fixtureIDs.insert(id).inserted else {
                throw MacLocalValidationManifestError.duplicateID(id)
            }
            guard (path as NSString).isAbsolutePath else {
                throw MacLocalValidationManifestError.nonAbsolutePath(id: id)
            }

            presentCategories.insert(fixture.category)
        }

        let missingCategories = MacLocalValidationCategory.allCases.filter {
            !presentCategories.contains($0)
        }
        guard missingCategories.isEmpty else {
            throw MacLocalValidationManifestError.missingCategories(missingCategories)
        }
    }
}

public enum MacLocalValidationPlaybackState: String, Equatable, Sendable {
    case ready
    case failed
    case timedOut = "timed_out"
}

public struct MacLocalValidationObservation: Equatable, Sendable {
    public var fixtureID: String
    public var category: MacLocalValidationCategory
    public var fileName: String
    public var sha256: String
    public var fixtureNotes: String
    public var metadataFacts: [String]
    public var inferredFacts: [String]
    public var unknowns: [String]
    public var limitations: [String]
    public var playbackState: MacLocalValidationPlaybackState
    public var playbackDetail: String
    public var visiblePresentationObservation: String

    public init(
        fixtureID: String,
        category: MacLocalValidationCategory,
        fileName: String,
        sha256: String,
        fixtureNotes: String,
        metadataFacts: [String],
        inferredFacts: [String],
        unknowns: [String],
        limitations: [String],
        playbackState: MacLocalValidationPlaybackState,
        playbackDetail: String,
        visiblePresentationObservation: String = "not_observed"
    ) {
        self.fixtureID = fixtureID
        self.category = category
        self.fileName = fileName
        self.sha256 = sha256
        self.fixtureNotes = fixtureNotes
        self.metadataFacts = metadataFacts
        self.inferredFacts = inferredFacts
        self.unknowns = unknowns
        self.limitations = limitations
        self.playbackState = playbackState
        self.playbackDetail = playbackDetail
        self.visiblePresentationObservation = visiblePresentationObservation
    }
}

public struct MacLocalValidationHost: Equatable, Sendable {
    public var generatedAt: Date
    public var operatingSystem: String
    public var display: MacDisplayDiagnostic

    public init(
        generatedAt: Date,
        operatingSystem: String,
        display: MacDisplayDiagnostic
    ) {
        self.generatedAt = generatedAt
        self.operatingSystem = operatingSystem
        self.display = display
    }
}

public enum MacLocalValidationReportRenderer {
    public static let presentationClaim =
        "Unknown and unverified. No custom Metal HDR or Dolby Vision rendering accuracy claim."

    public static func render(
        host: MacLocalValidationHost,
        observations: [MacLocalValidationObservation]
    ) -> String {
        var lines = [
            "# macOS Local Validation Record",
            "",
            "Generated: \(ISO8601DateFormatter().string(from: host.generatedAt))",
            "macOS: \(host.operatingSystem)",
            "",
            "This local record contains no media and no absolute media paths. AVPlayer readiness is a system open-path fact only; it does not prove HDR, HLG, or Dolby Vision presentation accuracy.",
            "",
            "## Display / EDR facts",
            "",
            "- \(displaySummary(host.display))",
            "- \(host.display.limitation)"
        ]

        for observation in observations {
            lines.append(contentsOf: [
                "",
                "## \(heading(observation.fixtureID))",
                "",
                "| Field | Record |",
                "|---|---|",
                "| Scenario | \(observation.category.rawValue) |",
                "| File name | \(table(observation.fileName)) |",
                "| SHA-256 | \(table(observation.sha256)) |",
                "| Fixture notes | \(table(observation.fixtureNotes)) |",
                "| AVFoundation metadata facts | \(table(observation.metadataFacts)) |",
                "| Inferred facts | \(table(observation.inferredFacts)) |",
                "| Unknowns | \(table(observation.unknowns)) |",
                "| Limitations | \(table(observation.limitations)) |",
                "| AVPlayer system playback state | \(observation.playbackState.rawValue): \(table(observation.playbackDetail)) |",
                "| EDR / display observation | \(table(displaySummary(host.display))) |",
                "| Visible presentation observation | \(table(observation.visiblePresentationObservation)) |",
                "| Presentation / rendering claim | \(presentationClaim) |"
            ])
        }

        lines.append(contentsOf: [
            "",
            "## Recording rules",
            "",
            "- Metadata facts, inferred facts, AVPlayer state, display facts, and presentation accuracy remain independent evidence.",
            "- A ready result means AVPlayer accepted the source; it does not establish correct playback or presentation.",
            "- A timed_out result is incomplete validation and must be rerun or investigated.",
            "- Visible observation is an operator note, not a color measurement or certification.",
            "- Keep this report, the fixture manifest, and all media out of Git."
        ])

        return lines.joined(separator: "\n") + "\n"
    }

    private static func displaySummary(_ display: MacDisplayDiagnostic) -> String {
        let trimmedName = display.screenName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmedName.flatMap { $0.isEmpty ? nil : $0 } ?? "unknown"
        let currentEDR = display.maximumCurrentEDRColorComponentValue
            .map { String(format: "%.2f", $0) } ?? "unknown"
        let potentialEDR = display.maximumPotentialEDRColorComponentValue
            .map { String(format: "%.2f", $0) } ?? "unknown"
        let referenceEDR = display.maximumReferenceEDRColorComponentValue
            .map { String(format: "%.2f", $0) } ?? "unknown"
        return [
            "Screen: \(name)",
            "Display supports EDR: \(display.supportsEDR)",
            "Current EDR headroom available: \(display.hasCurrentEDRHeadroom)",
            "Current maximum EDR component: \(currentEDR)",
            "Potential maximum EDR component: \(potentialEDR)",
            "Reference maximum EDR component: \(referenceEDR)"
        ].joined(separator: "; ")
    }

    private static func heading(_ value: String) -> String {
        value.replacingOccurrences(of: "\n", with: " ")
    }

    private static func table(_ values: [String]) -> String {
        values.isEmpty ? "none" : values.map(table).joined(separator: "<br>")
    }

    private static func table(_ value: String) -> String {
        value
            .replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "\r\n", with: "<br>")
            .replacingOccurrences(of: "\n", with: "<br>")
    }
}
