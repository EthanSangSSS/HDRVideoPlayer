import Foundation
import XCTest
@testable import HDRVideoPlayerMacCore

final class MacLocalValidationTests: XCTestCase {
    func testManifestRequiresAllValidationCategories() throws {
        let fixtures = allFixtures().filter { $0.category != .hlg }

        XCTAssertThrowsError(try MacLocalValidationManifest.validate(fixtures)) { error in
            XCTAssertEqual(
                error as? MacLocalValidationManifestError,
                .missingCategories([.hlg])
            )
        }
    }

    func testManifestRejectsDuplicateIDsAndRelativePaths() throws {
        var duplicateFixtures = allFixtures()
        duplicateFixtures[1].id = duplicateFixtures[0].id
        XCTAssertThrowsError(try MacLocalValidationManifest.validate(duplicateFixtures)) { error in
            XCTAssertEqual(
                error as? MacLocalValidationManifestError,
                .duplicateID("sdr-h264")
            )
        }

        var relativeFixtures = allFixtures()
        relativeFixtures[0].path = "fixtures/sdr.mp4"
        XCTAssertThrowsError(try MacLocalValidationManifest.validate(relativeFixtures)) { error in
            XCTAssertEqual(
                error as? MacLocalValidationManifestError,
                .nonAbsolutePath(id: "sdr-h264")
            )
        }
    }

    func testReportKeepsEvidenceLayersAndClaimSeparate() {
        let host = MacLocalValidationHost(
            generatedAt: Date(timeIntervalSince1970: 0),
            operatingSystem: "macOS test",
            display: MacDisplayDiagnostic(
                screenName: "",
                maximumEDRColorComponentValue: 1.75
            )
        )
        let observation = MacLocalValidationObservation(
            fixtureID: "hdr10-main10",
            category: .hdr10HEVCMain10,
            fileName: "fixture.mp4",
            sha256: "abc123",
            fixtureNotes: "authorized local fixture",
            metadataFacts: ["Video track 0 codec: hvc1", "Video track 0 transfer function: pq"],
            inferredFacts: ["Extension-based container candidate: mp4"],
            unknowns: ["Presentation accuracy is unknown and unverified."],
            limitations: ["Metadata facts do not prove presentation."],
            playbackState: .ready,
            playbackDetail: "AVPlayer accepted the source. Presentation accuracy remains unknown."
        )

        let report = MacLocalValidationReportRenderer.render(
            host: host,
            observations: [observation]
        )

        XCTAssertTrue(report.contains("AVFoundation metadata facts"))
        XCTAssertTrue(report.contains("AVPlayer system playback state | ready"))
        XCTAssertTrue(report.contains("Screen: unknown"))
        XCTAssertTrue(report.contains("maximum EDR color component value: 1.75"))
        XCTAssertTrue(report.contains(MacLocalValidationReportRenderer.presentationClaim))
        XCTAssertFalse(report.contains("/licensed-media/"))
    }

    private func allFixtures() -> [MacLocalValidationFixture] {
        [
            MacLocalValidationFixture(id: "sdr-h264", category: .sdrH264MP4, path: "/licensed-media/sdr.mp4"),
            MacLocalValidationFixture(id: "hdr10-main10", category: .hdr10HEVCMain10, path: "/licensed-media/hdr10.mp4"),
            MacLocalValidationFixture(id: "hlg", category: .hlg, path: "/licensed-media/hlg.mp4"),
            MacLocalValidationFixture(id: "dv81", category: .dolbyVisionProfile81Fallback, path: "/licensed-media/dv81.mp4"),
            MacLocalValidationFixture(id: "dv5-or-7", category: .dolbyVisionProfile5Or7DetectOnly, path: "/licensed-media/dv5.mp4"),
            MacLocalValidationFixture(id: "unsupported", category: .unsupportedOrMissingCodec, path: "/licensed-media/unsupported.mkv")
        ]
    }
}
