import Foundation
import XCTest
@testable import HDRVideoPlayerMacCore

final class MacMetadataModelTests: XCTestCase {
    func testUnsupportedAssetPreservesUnknownHDRAndPresentation() async {
        let url = URL(fileURLWithPath: "/missing/unsupported.bin")

        let asset = await MacMetadataProbe().probe(url)

        XCTAssertEqual(asset.hdrSignal.transfer, .unknown)
        XCTAssertEqual(asset.hdrSignal.primaries, .unknown)
        XCTAssertEqual(asset.hdrSignal.matrix, .unknown)
        XCTAssertEqual(asset.presentationClaim.path, .unknown)
        XCTAssertEqual(asset.presentationClaim.accuracy, .unverified)
        XCTAssertTrue(asset.videoStreams.isEmpty)
    }

    func testFilenameDolbyVisionMarkerIsLowConfidenceCandidateOnly() async {
        let url = URL(fileURLWithPath: "/missing/movie.dovi.profile8.1.mp4")

        let asset = await MacMetadataProbe().probe(url)

        XCTAssertTrue(asset.dolbyVision.markersDetected)
        XCTAssertEqual(asset.dolbyVision.profileCandidate, .profile81)
        XCTAssertEqual(asset.dolbyVision.evidenceSource, .filenameMarker)
        XCTAssertEqual(asset.probeEvidence.confidence, .heuristic)
        XCTAssertTrue(asset.probeEvidence.sources.contains(.filenameMarker))
        XCTAssertEqual(asset.presentationClaim.path, .unknown)
    }

    func testEDRModelRepresentsUnavailableAndAvailableValues() {
        let unavailable = MacDisplayDiagnostic.unavailable
        let available = MacDisplayDiagnostic(
            screenName: "Test display",
            maximumEDRColorComponentValue: 1.6
        )

        XCTAssertNil(unavailable.maximumEDRColorComponentValue)
        XCTAssertFalse(unavailable.isEDRAvailable)
        XCTAssertEqual(available.maximumEDRColorComponentValue, 1.6)
        XCTAssertTrue(available.isEDRAvailable)
    }
}
