import Foundation

public struct MacMediaAsset: Equatable, Sendable {
    public var fileName: String
    public var container: String
    public var videoStreams: [MacVideoStreamInfo]
    public var audioStreams: [MacAudioStreamInfo]
    public var hdrSignal: MacHDRSignal
    public var dolbyVision: MacDolbyVisionInfo
    public var probeEvidence: MacProbeEvidence
    public var systemPlaybackState: MacSystemPlaybackState
    public var presentationClaim: MacPresentationClaim

    public init(
        fileName: String,
        container: String,
        videoStreams: [MacVideoStreamInfo] = [],
        audioStreams: [MacAudioStreamInfo] = [],
        hdrSignal: MacHDRSignal = .unknown,
        dolbyVision: MacDolbyVisionInfo = .unknown,
        probeEvidence: MacProbeEvidence = .unknown,
        systemPlaybackState: MacSystemPlaybackState = .idle,
        presentationClaim: MacPresentationClaim = .unknown
    ) {
        self.fileName = fileName
        self.container = container
        self.videoStreams = videoStreams
        self.audioStreams = audioStreams
        self.hdrSignal = hdrSignal
        self.dolbyVision = dolbyVision
        self.probeEvidence = probeEvidence
        self.systemPlaybackState = systemPlaybackState
        self.presentationClaim = presentationClaim
    }
}

public struct MacVideoStreamInfo: Equatable, Sendable {
    public var index: Int
    public var codec: String
    public var width: Int?
    public var height: Int?
    public var nominalFrameRate: Double?
    public var bitDepthCandidate: Int?
    public var pixelFormat: String
    public var colorPrimaries: MacColorPrimaries
    public var transferFunction: MacHDRTransfer
    public var yCbCrMatrix: MacMatrixCoefficients

    public init(
        index: Int,
        codec: String = "unknown",
        width: Int? = nil,
        height: Int? = nil,
        nominalFrameRate: Double? = nil,
        bitDepthCandidate: Int? = nil,
        pixelFormat: String = "unknown",
        colorPrimaries: MacColorPrimaries = .unknown,
        transferFunction: MacHDRTransfer = .unknown,
        yCbCrMatrix: MacMatrixCoefficients = .unknown
    ) {
        self.index = index
        self.codec = codec
        self.width = width
        self.height = height
        self.nominalFrameRate = nominalFrameRate
        self.bitDepthCandidate = bitDepthCandidate
        self.pixelFormat = pixelFormat
        self.colorPrimaries = colorPrimaries
        self.transferFunction = transferFunction
        self.yCbCrMatrix = yCbCrMatrix
    }
}

public struct MacAudioStreamInfo: Equatable, Sendable {
    public var index: Int
    public var codec: String
    public var channels: Int?
    public var sampleRate: Double?

    public init(
        index: Int,
        codec: String = "unknown",
        channels: Int? = nil,
        sampleRate: Double? = nil
    ) {
        self.index = index
        self.codec = codec
        self.channels = channels
        self.sampleRate = sampleRate
    }
}

public struct MacHDRSignal: Equatable, Sendable {
    public var transfer: MacHDRTransfer
    public var primaries: MacColorPrimaries
    public var matrix: MacMatrixCoefficients
    public var capabilityState: MacCapabilityState
    public var limitations: [String]

    public init(
        transfer: MacHDRTransfer,
        primaries: MacColorPrimaries,
        matrix: MacMatrixCoefficients,
        capabilityState: MacCapabilityState,
        limitations: [String]
    ) {
        self.transfer = transfer
        self.primaries = primaries
        self.matrix = matrix
        self.capabilityState = capabilityState
        self.limitations = limitations
    }

    public static let unknown = MacHDRSignal(
        transfer: .unknown,
        primaries: .unknown,
        matrix: .unknown,
        capabilityState: .notStarted,
        limitations: [
            "HDR metadata is unavailable. HDR10 mastering metadata, MaxCLL, and MaxFALL are not parsed."
        ]
    )
}

public enum MacHDRTransfer: String, Equatable, Sendable {
    case unknown
    case sdr
    case pq
    case hlg
}

public enum MacColorPrimaries: String, Equatable, Sendable {
    case unknown
    case bt709
    case bt2020
    case p3
}

public enum MacMatrixCoefficients: String, Equatable, Sendable {
    case unknown
    case bt709
    case bt2020
}

public enum MacCapabilityState: String, Equatable, Sendable {
    case notStarted
    case detectOnly
    case fallbackPlayback
    case experimental
    case validated
}

public struct MacDolbyVisionInfo: Equatable, Sendable {
    public var markersDetected: Bool
    public var profileCandidate: MacDolbyVisionProfileCandidate
    public var evidenceSource: MacDolbyVisionEvidenceSource
    public var limitation: String

    public init(
        markersDetected: Bool,
        profileCandidate: MacDolbyVisionProfileCandidate,
        evidenceSource: MacDolbyVisionEvidenceSource,
        limitation: String
    ) {
        self.markersDetected = markersDetected
        self.profileCandidate = profileCandidate
        self.evidenceSource = evidenceSource
        self.limitation = limitation
    }

    public static let unknown = MacDolbyVisionInfo(
        markersDetected: false,
        profileCandidate: .unknown,
        evidenceSource: .none,
        limitation: "Dolby Vision RPU, profile, level, base layer, and dynamic metadata application are not parsed or implemented."
    )
}

public enum MacDolbyVisionProfileCandidate: String, Equatable, Sendable {
    case unknown
    case profile5
    case profile7
    case profile81
    case profile84
}

public enum MacDolbyVisionEvidenceSource: String, Equatable, Sendable {
    case none
    case filenameMarker
    case avFoundationMetadata
}

public struct MacProbeEvidence: Equatable, Sendable {
    public var confidence: MacProbeConfidence
    public var sources: [MacProbeSource]
    public var limitation: String

    public init(
        confidence: MacProbeConfidence,
        sources: [MacProbeSource],
        limitation: String
    ) {
        self.confidence = confidence
        self.sources = sources
        self.limitation = limitation
    }

    public static let unknown = MacProbeEvidence(
        confidence: .unknown,
        sources: [],
        limitation: "No metadata evidence is available."
    )
}

public enum MacProbeConfidence: String, Equatable, Sendable {
    case unknown
    case heuristic
    case parsedMetadata
}

public enum MacProbeSource: String, Equatable, Sendable {
    case fileExtension
    case filenameMarker
    case avFoundationTrack
    case coreMediaFormatDescription
    case screenEDR
}

public struct MacPresentationClaim: Equatable, Sendable {
    public var path: MacPresentationPath
    public var accuracy: MacPresentationAccuracy
    public var limitation: String

    public init(
        path: MacPresentationPath,
        accuracy: MacPresentationAccuracy,
        limitation: String
    ) {
        self.path = path
        self.accuracy = accuracy
        self.limitation = limitation
    }

    public static let unknown = MacPresentationClaim(
        path: .unknown,
        accuracy: .unverified,
        limitation: "Unknown and unverified. No custom Metal HDR or Dolby Vision rendering accuracy claim."
    )

    public static let systemPreview = MacPresentationClaim(
        path: .systemAVPlayer,
        accuracy: .unverified,
        limitation: "Unknown and unverified. No custom Metal HDR or Dolby Vision rendering accuracy claim."
    )
}

public enum MacPresentationPath: String, Equatable, Sendable {
    case unknown
    case systemAVPlayer
    case metalEDRTestPattern
    case customMetalVideo
}

public enum MacPresentationAccuracy: String, Equatable, Sendable {
    case unknown
    case unverified
    case observed
    case measured
}
