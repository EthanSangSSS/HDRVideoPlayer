import AVFoundation
import CoreMedia
import Foundation

public struct MacMetadataProbe: Sendable {
    public init() {}

    public func probe(_ url: URL) async -> MacMediaAsset {
        var asset = fallbackAsset(for: url)

        guard url.isFileURL, FileManager.default.fileExists(atPath: url.path) else {
            return asset
        }

        let avAsset = AVURLAsset(url: url)

        do {
            let tracks = try await avAsset.load(.tracks)
            var videoStreams: [MacVideoStreamInfo] = []
            var audioStreams: [MacAudioStreamInfo] = []
            var usedFormatDescription = false

            for track in tracks {
                if track.mediaType == .video {
                    let result = try await videoStream(from: track, index: videoStreams.count)
                    videoStreams.append(result.stream)
                    usedFormatDescription = usedFormatDescription || result.usedFormatDescription
                } else if track.mediaType == .audio {
                    let result = try await audioStream(from: track, index: audioStreams.count)
                    audioStreams.append(result.stream)
                    usedFormatDescription = usedFormatDescription || result.usedFormatDescription
                }
            }

            guard !tracks.isEmpty else {
                asset.probeEvidence.limitation = "AVFoundation loaded the asset but exposed no tracks. Extension and filename evidence remain heuristic."
                return asset
            }

            asset.videoStreams = videoStreams
            asset.audioStreams = audioStreams
            asset.hdrSignal = hdrSignal(from: videoStreams)
            asset.probeEvidence = MacProbeEvidence(
                confidence: .parsedMetadata,
                sources: parsedSources(for: asset, usedFormatDescription: usedFormatDescription),
                limitation: "AVFoundation and CoreMedia expose selected track and format-description fields only. Mastering metadata and dynamic metadata application remain unverified."
            )
            return asset
        } catch {
            asset.probeEvidence.limitation = "AVFoundation metadata loading failed (\(type(of: error))). Extension and filename evidence remain heuristic."
            return asset
        }
    }

    public func fallbackAsset(for url: URL) -> MacMediaAsset {
        let fileName = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        let dolbyVision = dolbyVisionCandidate(from: fileName)
        var sources: [MacProbeSource] = []

        if !fileExtension.isEmpty {
            sources.append(.fileExtension)
        }

        if dolbyVision.markersDetected {
            sources.append(.filenameMarker)
        }

        let confidence: MacProbeConfidence = sources.isEmpty ? .unknown : .heuristic
        return MacMediaAsset(
            fileName: fileName,
            container: fileExtension.isEmpty ? "unknown" : fileExtension,
            hdrSignal: .unknown,
            dolbyVision: dolbyVision,
            probeEvidence: MacProbeEvidence(
                confidence: confidence,
                sources: sources,
                limitation: "Only file-extension and filename-marker heuristics are available. System playback support and presentation accuracy are not inferred."
            )
        )
    }

    private func videoStream(
        from track: AVAssetTrack,
        index: Int
    ) async throws -> (stream: MacVideoStreamInfo, usedFormatDescription: Bool) {
        let naturalSize = try await track.load(.naturalSize)
        let nominalFrameRate = try await track.load(.nominalFrameRate)
        let formatDescriptions = try await track.load(.formatDescriptions)
        let firstDescription = formatDescriptions.first
        let extensions = firstDescription.flatMap(formatExtensions)

        return (
            MacVideoStreamInfo(
                index: index,
                codec: firstDescription.map { fourCCString(CMFormatDescriptionGetMediaSubType($0)) } ?? "unknown",
                width: naturalSize.width > 0 ? Int(naturalSize.width.rounded()) : nil,
                height: naturalSize.height > 0 ? Int(naturalSize.height.rounded()) : nil,
                nominalFrameRate: nominalFrameRate > 0 ? Double(nominalFrameRate) : nil,
                bitDepthCandidate: nil,
                pixelFormat: "unknown",
                colorPrimaries: mapPrimaries(extensionValue(extensions, key: kCMFormatDescriptionExtension_ColorPrimaries)),
                transferFunction: mapTransfer(extensionValue(extensions, key: kCMFormatDescriptionExtension_TransferFunction)),
                yCbCrMatrix: mapMatrix(extensionValue(extensions, key: kCMFormatDescriptionExtension_YCbCrMatrix))
            ),
            firstDescription != nil
        )
    }

    private func audioStream(
        from track: AVAssetTrack,
        index: Int
    ) async throws -> (stream: MacAudioStreamInfo, usedFormatDescription: Bool) {
        let formatDescriptions = try await track.load(.formatDescriptions)
        let firstDescription = formatDescriptions.first
        let basicDescription = firstDescription.flatMap(CMAudioFormatDescriptionGetStreamBasicDescription)

        return (
            MacAudioStreamInfo(
                index: index,
                codec: firstDescription.map { fourCCString(CMFormatDescriptionGetMediaSubType($0)) } ?? "unknown",
                channels: basicDescription.map { Int($0.pointee.mChannelsPerFrame) },
                sampleRate: basicDescription.map { $0.pointee.mSampleRate }
            ),
            firstDescription != nil
        )
    }

    private func parsedSources(for asset: MacMediaAsset, usedFormatDescription: Bool) -> [MacProbeSource] {
        var sources = asset.probeEvidence.sources

        if !sources.contains(.avFoundationTrack) {
            sources.append(.avFoundationTrack)
        }

        if usedFormatDescription, !sources.contains(.coreMediaFormatDescription) {
            sources.append(.coreMediaFormatDescription)
        }

        return sources
    }

    private func hdrSignal(from videoStreams: [MacVideoStreamInfo]) -> MacHDRSignal {
        let transfer = videoStreams.lazy.map(\.transferFunction).first { $0 != .unknown } ?? .unknown
        let primaries = videoStreams.lazy.map(\.colorPrimaries).first { $0 != .unknown } ?? .unknown
        let matrix = videoStreams.lazy.map(\.yCbCrMatrix).first { $0 != .unknown } ?? .unknown
        let hasKnownColorFact = transfer != .unknown || primaries != .unknown || matrix != .unknown

        return MacHDRSignal(
            transfer: transfer,
            primaries: primaries,
            matrix: matrix,
            capabilityState: hasKnownColorFact ? .detectOnly : .notStarted,
            limitations: [
                "Color properties are metadata facts only. HDR10 mastering metadata, MaxCLL, MaxFALL, and presentation accuracy are not validated."
            ]
        )
    }

    private func dolbyVisionCandidate(from fileName: String) -> MacDolbyVisionInfo {
        let normalized = fileName.lowercased()
        let markerTokens = ["dolbyvision", "dolby.vision", "dolby-vision", "dovi", "dvhe", "dvh1"]
        let markersDetected = markerTokens.contains { normalized.contains($0) }

        guard markersDetected else {
            return .unknown
        }

        let profile: MacDolbyVisionProfileCandidate
        if containsAny(normalized, ["profile8.1", "profile-8.1", "profile_8.1", "p8.1", "p81", "dv81"]) {
            profile = .profile81
        } else if containsAny(normalized, ["profile8.4", "profile-8.4", "profile_8.4", "p8.4", "p84", "dv84"]) {
            profile = .profile84
        } else if containsAny(normalized, ["profile5", "profile-5", "profile_5", "p5", "dv5"]) {
            profile = .profile5
        } else if containsAny(normalized, ["profile7", "profile-7", "profile_7", "p7", "dv7"]) {
            profile = .profile7
        } else {
            profile = .unknown
        }

        return MacDolbyVisionInfo(
            markersDetected: true,
            profileCandidate: profile,
            evidenceSource: .filenameMarker,
            limitation: "Filename marker only. Dolby Vision RPU, profile, level, base layer, and dynamic metadata application are not parsed or implemented."
        )
    }

    private func containsAny(_ value: String, _ candidates: [String]) -> Bool {
        candidates.contains { value.contains($0) }
    }

    private func formatExtensions(_ description: CMFormatDescription) -> NSDictionary? {
        CMFormatDescriptionGetExtensions(description) as NSDictionary?
    }

    private func extensionValue(_ extensions: NSDictionary?, key: CFString) -> String? {
        guard let value = extensions?[key] else {
            return nil
        }

        return String(describing: value)
    }

    private func mapPrimaries(_ value: String?) -> MacColorPrimaries {
        let normalized = value?.uppercased() ?? ""
        if normalized.contains("2020") { return .bt2020 }
        if normalized.contains("P3") { return .p3 }
        if normalized.contains("709") { return .bt709 }
        return .unknown
    }

    private func mapTransfer(_ value: String?) -> MacHDRTransfer {
        let normalized = value?.uppercased() ?? ""
        if normalized.contains("2084") || normalized.contains("PQ") { return .pq }
        if normalized.contains("HLG") || normalized.contains("2100") { return .hlg }
        if normalized.contains("709") || normalized.contains("SRGB") { return .sdr }
        return .unknown
    }

    private func mapMatrix(_ value: String?) -> MacMatrixCoefficients {
        let normalized = value?.uppercased() ?? ""
        if normalized.contains("2020") { return .bt2020 }
        if normalized.contains("709") { return .bt709 }
        return .unknown
    }

    private func fourCCString(_ code: FourCharCode) -> String {
        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xff),
            UInt8((code >> 16) & 0xff),
            UInt8((code >> 8) & 0xff),
            UInt8(code & 0xff)
        ]

        let printable = bytes.allSatisfy { (32...126).contains($0) }
        return printable ? String(bytes: bytes, encoding: .ascii) ?? "unknown" : String(format: "0x%08X", code)
    }
}
