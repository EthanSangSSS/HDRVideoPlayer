import XCTest
@testable import HDRVideoPlayerMacCore

final class MacPlaybackStateTests: XCTestCase {
    func testReadySystemPreviewKeepsPresentationUnknownAndUnverified() {
        let initial = MacMediaAsset(fileName: "fixture.mp4", container: "mp4")

        let ready = initial.withSystemPlaybackState(.ready)

        XCTAssertEqual(ready.systemPlaybackState, .ready)
        XCTAssertEqual(ready.presentationClaim.path, .systemAVPlayer)
        XCTAssertEqual(ready.presentationClaim.accuracy, .unverified)
        XCTAssertTrue(ready.presentationClaim.limitation.contains("Unknown and unverified"))
        XCTAssertTrue(ready.presentationClaim.limitation.contains("No custom Metal"))
    }
}
