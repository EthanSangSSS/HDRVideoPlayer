import XCTest
@testable import HDRVideoPlayerMacCore

final class MacDiagnosticReportTests: XCTestCase {
    func testReportContainsAllEvidenceSections() {
        let asset = MacMediaAsset(
            fileName: "fixture.mp4",
            container: "mp4",
            probeEvidence: MacProbeEvidence(
                confidence: .heuristic,
                sources: [.fileExtension],
                limitation: "Heuristic fixture."
            )
        )

        let report = MacDiagnosticReportFactory.make(asset: asset, display: .unavailable)

        XCTAssertFalse(report.facts.isEmpty)
        XCTAssertFalse(report.inferredFacts.isEmpty)
        XCTAssertFalse(report.unknowns.isEmpty)
        XCTAssertFalse(report.limitations.isEmpty)
        XCTAssertFalse(report.nextTests.isEmpty)
    }
}
