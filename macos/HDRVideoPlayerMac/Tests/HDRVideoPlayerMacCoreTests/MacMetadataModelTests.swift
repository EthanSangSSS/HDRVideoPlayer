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
            maximumEDRColorComponentValue: 1.6,
            maximumPotentialEDRColorComponentValue: 2.0,
            maximumReferenceEDRColorComponentValue: 1.4
        )

        XCTAssertNil(unavailable.maximumEDRColorComponentValue)
        XCTAssertFalse(unavailable.isEDRAvailable)
        XCTAssertEqual(available.maximumEDRColorComponentValue, 1.6)
        XCTAssertEqual(available.maximumPotentialEDRColorComponentValue, 2.0)
        XCTAssertEqual(available.maximumReferenceEDRColorComponentValue, 1.4)
        XCTAssertTrue(available.isEDRAvailable)
    }
}
