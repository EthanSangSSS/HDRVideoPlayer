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

    func testEDRCapableDisplayCanHaveNoCurrentHeadroom() {
        let display = diagnostic(current: 1.0, potential: 4.0)

        XCTAssertTrue(display.supportsEDR)
        XCTAssertFalse(display.hasCurrentEDRHeadroom)
    }

    func testEDRCapableDisplayCanHaveCurrentHeadroom() {
        let display = diagnostic(current: 2.0, potential: 4.0)

        XCTAssertTrue(display.supportsEDR)
        XCTAssertTrue(display.hasCurrentEDRHeadroom)
    }

    func testSDRDisplayHasNeitherCapabilityNorCurrentHeadroom() {
        let display = diagnostic(current: 1.0, potential: 1.0)

        XCTAssertFalse(display.supportsEDR)
        XCTAssertFalse(display.hasCurrentEDRHeadroom)
    }

    func testUnknownEDRValuesProduceNoPositiveInference() {
        let display = MacDisplayDiagnostic.unavailable

        XCTAssertNil(display.maximumCurrentEDRColorComponentValue)
        XCTAssertNil(display.maximumPotentialEDRColorComponentValue)
        XCTAssertNil(display.maximumReferenceEDRColorComponentValue)
        XCTAssertFalse(display.supportsEDR)
        XCTAssertFalse(display.hasCurrentEDRHeadroom)
        XCTAssertTrue(display.limitation.contains("Missing values produce no positive inference"))
    }

    private func diagnostic(current: Double, potential: Double) -> MacDisplayDiagnostic {
        MacDisplayDiagnostic(
            screenName: "Test display",
            maximumCurrentEDRColorComponentValue: current,
            maximumPotentialEDRColorComponentValue: potential,
            maximumReferenceEDRColorComponentValue: 1.4
        )
    }
}
