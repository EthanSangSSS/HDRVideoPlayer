import XCTest
@testable import HDRVideoPlayerMacCore

final class MacEDRTestPatternTests: XCTestCase {
    func testReferencePatternUsesBoundedStaticEDRConfiguration() {
        let configuration = MacEDRTestPatternConfiguration.reference

        XCTAssertEqual(configuration.pixelFormatName, "rgba16Float")
        XCTAssertEqual(configuration.colorSpaceName, "extendedLinearSRGB")
        XCTAssertTrue(configuration.requestsExtendedDynamicRange)
        XCTAssertEqual(configuration.colorStops.count, 8)
        XCTAssertEqual(configuration.maximumSubmittedComponent, 4)
        XCTAssertFalse(configuration.acceptsVideoFrames)
        XCTAssertTrue(configuration.colorStops.contains { $0.maximumComponent == 1 })
        XCTAssertTrue(configuration.colorStops.contains { $0.maximumComponent > 1 })
    }

    func testReportKeepsSubmittedPixelsDisplayFactsAndAccuracySeparate() {
        let display = MacDisplayDiagnostic(
            screenName: "Test display",
            maximumCurrentEDRColorComponentValue: 1.5,
            maximumPotentialEDRColorComponentValue: 2.0,
            maximumReferenceEDRColorComponentValue: 1.25
        )

        let report = MacEDRTestPatternReportFactory.make(display: display)

        XCTAssertTrue(report.rendererFacts.contains("Maximum submitted component: 4.00"))
        XCTAssertTrue(report.rendererFacts.contains("Decoded video frames accepted: false"))
        XCTAssertTrue(report.displayFacts.contains("Display supports EDR: true"))
        XCTAssertTrue(report.displayFacts.contains("Current EDR headroom available: true"))
        XCTAssertTrue(report.displayFacts.contains("Current maximum EDR component: 1.50"))
        XCTAssertTrue(report.displayFacts.contains("Potential maximum EDR component: 2.00"))
        XCTAssertTrue(report.displayFacts.contains("Reference maximum EDR component: 1.25"))
        XCTAssertEqual(report.presentationClaim.path, .metalEDRTestPattern)
        XCTAssertEqual(report.presentationClaim.accuracy, .unverified)
        XCTAssertTrue(report.presentationClaim.limitation.contains("Unknown and unverified"))
        XCTAssertTrue(report.unknowns.contains { $0.contains("Dolby Vision") })
        XCTAssertTrue(report.limitations.contains { $0.contains("No AVPlayer") })
    }
}
