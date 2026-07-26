import AppKit
import AVFoundation
import CryptoKit
import Darwin
import Foundation
import HDRVideoPlayerMacCore

private enum LocalValidationCLIError: Error, LocalizedError {
    case usage(String)
    case repositoryRootRequired
    case manifestMustBeOutsideRepository
    case fixtureMustBeOutsideRepository(String)
    case fixtureNotFound(String)
    case outputPathNotAllowed
    case timedOut([String])

    var errorDescription: String? {
        switch self {
        case let .usage(message):
            return message
        case .repositoryRootRequired:
            return "Run this command from the HDRVideoPlayer repository root."
        case .manifestMustBeOutsideRepository:
            return "Fixture manifest must stay outside the repository."
        case let .fixtureMustBeOutsideRepository(id):
            return "Fixture '\(id)' must stay outside the repository."
        case let .fixtureNotFound(id):
            return "Fixture '\(id)' was not found or is not a regular file."
        case .outputPathNotAllowed:
            return "Output inside the repository is allowed only under artifacts/."
        case let .timedOut(ids):
            return "Validation timed out for: \(ids.joined(separator: ", ")). The local report was still written."
        }
    }
}

private struct LocalValidationOptions {
    var manifestURL: URL
    var outputURL: URL?
    var timeoutSeconds: TimeInterval

    static func parse(_ arguments: [String]) throws -> LocalValidationOptions? {
        var manifestPath: String?
        var outputPath: String?
        var timeoutSeconds: TimeInterval = 15
        var index = 0

        while index < arguments.count {
            let argument = arguments[index]
            if argument == "--help" || argument == "-h" {
                print(usage)
                return nil
            }

            guard index + 1 < arguments.count else {
                throw LocalValidationCLIError.usage("Missing value for \(argument).\n\n\(usage)")
            }
            let value = arguments[index + 1]

            switch argument {
            case "--manifest":
                manifestPath = value
            case "--output":
                outputPath = value
            case "--timeout-seconds":
                guard let parsed = TimeInterval(value), parsed > 0, parsed <= 120 else {
                    throw LocalValidationCLIError.usage("--timeout-seconds must be between 1 and 120.")
                }
                timeoutSeconds = parsed
            default:
                throw LocalValidationCLIError.usage("Unknown argument: \(argument)\n\n\(usage)")
            }

            index += 2
        }

        guard let manifestPath else {
            throw LocalValidationCLIError.usage("--manifest is required.\n\n\(usage)")
        }

        return LocalValidationOptions(
            manifestURL: URL(fileURLWithPath: manifestPath),
            outputURL: outputPath.map { URL(fileURLWithPath: $0) },
            timeoutSeconds: timeoutSeconds
        )
    }

    private static let usage = """
    Usage:
      swift run --package-path macos/HDRVideoPlayerMac HDRVideoPlayerMacLocalValidation \\
        --manifest /absolute/path/macos-local-validation-fixtures.json \\
        [--output /absolute/path/report.md] [--timeout-seconds 15]
    """
}

@main
private struct HDRVideoPlayerMacLocalValidation {
    @MainActor
    static func main() async {
        do {
            guard let options = try LocalValidationOptions.parse(Array(CommandLine.arguments.dropFirst())) else {
                return
            }
            try await run(options)
        } catch {
            let message = "error: \(error.localizedDescription)\n"
            FileHandle.standardError.write(Data(message.utf8))
            exit(EXIT_FAILURE)
        }
    }

    @MainActor
    private static func run(_ options: LocalValidationOptions) async throws {
        let fileManager = FileManager.default
        let repositoryRoot = canonicalURL(
            URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        )
        let packageManifest = repositoryRoot.appendingPathComponent(
            "macos/HDRVideoPlayerMac/Package.swift",
            isDirectory: false
        )
        guard fileManager.fileExists(atPath: packageManifest.path) else {
            throw LocalValidationCLIError.repositoryRootRequired
        }

        let manifestURL = canonicalURL(options.manifestURL)
        guard !isInside(manifestURL, root: repositoryRoot) else {
            throw LocalValidationCLIError.manifestMustBeOutsideRepository
        }

        let fixtures = try MacLocalValidationManifest.decode(Data(contentsOf: manifestURL))
        let fixtureURLs = try fixtures.map { fixture -> URL in
            let url = canonicalURL(URL(fileURLWithPath: fixture.path))
            guard !isInside(url, root: repositoryRoot) else {
                throw LocalValidationCLIError.fixtureMustBeOutsideRepository(fixture.id)
            }

            let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
            guard values?.isRegularFile == true else {
                throw LocalValidationCLIError.fixtureNotFound(fixture.id)
            }
            return url
        }

        let outputURL = canonicalURL(options.outputURL ?? defaultOutputURL(repositoryRoot: repositoryRoot))
        let artifactsRoot = canonicalURL(repositoryRoot.appendingPathComponent("artifacts", isDirectory: true))
        if isInside(outputURL, root: repositoryRoot), !isInside(outputURL, root: artifactsRoot) {
            throw LocalValidationCLIError.outputPathNotAllowed
        }
        try fileManager.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let probe = MacMetadataProbe()
        let display = MacDisplayDiagnostics.current()
        var observations: [MacLocalValidationObservation] = []

        for (fixture, url) in zip(fixtures, fixtureURLs) {
            print("Validating \(fixture.id)...")
            let hash = try sha256(url)
            let probedAsset = await probe.probe(url)
            let playback = await playbackOutcome(url: url, timeoutSeconds: options.timeoutSeconds)
            let systemState: MacSystemPlaybackState
            switch playback.state {
            case .ready:
                systemState = .ready
            case .failed:
                systemState = .failed
            case .timedOut:
                systemState = .loading
            }
            let report = MacDiagnosticReportFactory.make(
                asset: probedAsset.withSystemPlaybackState(systemState)
            )
            let redact: (String) -> String = {
                redacted($0, localPaths: [fixture.path, url.path])
            }

            observations.append(
                MacLocalValidationObservation(
                    fixtureID: fixture.id,
                    category: fixture.category,
                    fileName: url.lastPathComponent,
                    sha256: hash,
                    fixtureNotes: redact(fixture.notes ?? "none"),
                    metadataFacts: report.facts.map(redact),
                    inferredFacts: report.inferredFacts.map(redact),
                    unknowns: report.unknowns.map(redact),
                    limitations: report.limitations.map(redact),
                    playbackState: playback.state,
                    playbackDetail: redact(playback.detail)
                )
            )
            print("  AVPlayer state: \(playback.state.rawValue)")
        }

        let host = MacLocalValidationHost(
            generatedAt: Date(),
            operatingSystem: ProcessInfo.processInfo.operatingSystemVersionString,
            display: display
        )
        let markdown = MacLocalValidationReportRenderer.render(
            host: host,
            observations: observations
        )
        try markdown.write(to: outputURL, atomically: true, encoding: .utf8)
        print("Validation report: \(outputURL.path)")

        let timedOutIDs = observations
            .filter { $0.playbackState == .timedOut }
            .map(\.fixtureID)
        if !timedOutIDs.isEmpty {
            throw LocalValidationCLIError.timedOut(timedOutIDs)
        }
    }

    @MainActor
    private static func playbackOutcome(
        url: URL,
        timeoutSeconds: TimeInterval
    ) async -> (state: MacLocalValidationPlaybackState, detail: String) {
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        let deadline = Date().addingTimeInterval(timeoutSeconds)

        defer {
            player.replaceCurrentItem(with: nil)
        }

        while Date() < deadline {
            switch item.status {
            case .readyToPlay:
                return (
                    .ready,
                    "AVPlayer accepted the source. Presentation accuracy remains unknown."
                )
            case .failed:
                let detail = item.error?.localizedDescription ?? "unknown error"
                return (.failed, "AVPlayer failed to open the source (\(detail)).")
            case .unknown:
                try? await Task.sleep(nanoseconds: 100_000_000)
            @unknown default:
                return (.failed, "AVPlayer returned an unknown item status.")
            }
        }

        return (
            .timedOut,
            "AVPlayer did not reach ready or failed within \(String(format: "%.0f", timeoutSeconds)) seconds."
        )
    }

    private static func sha256(_ url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()

        while let data = try handle.read(upToCount: 1_048_576), !data.isEmpty {
            hasher.update(data: data)
        }

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func defaultOutputURL(repositoryRoot: URL) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return repositoryRoot
            .appendingPathComponent("artifacts/macos-local-validation", isDirectory: true)
            .appendingPathComponent("macos-local-validation-\(formatter.string(from: Date())).md")
    }

    private static func canonicalURL(_ url: URL) -> URL {
        url.standardizedFileURL.resolvingSymlinksInPath()
    }

    private static func redacted(_ value: String, localPaths: [String]) -> String {
        localPaths.reduce(value) { partialResult, path in
            guard !path.isEmpty else { return partialResult }
            return partialResult.replacingOccurrences(of: path, with: "<redacted-local-path>")
        }
    }

    private static func isInside(_ url: URL, root: URL) -> Bool {
        let path = canonicalURL(url).path
        let rootPath = canonicalURL(root).path
        return path == rootPath || path.hasPrefix(rootPath + "/")
    }
}
