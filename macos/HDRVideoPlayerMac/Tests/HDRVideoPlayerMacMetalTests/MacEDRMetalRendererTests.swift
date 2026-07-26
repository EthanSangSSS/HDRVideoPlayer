import AppKit
import CoreGraphics
import Metal
import MetalKit
import QuartzCore
import XCTest
@testable import HDRVideoPlayerMacCore
@testable import HDRVideoPlayerMacMetal

final class MacEDRMetalRendererTests: XCTestCase {
    func testOffscreenFP16ReadbackPreservesEveryStaticColorStop() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal is unavailable on this test host.")
        }

        let result = try MacEDRMetalReadbackValidator.render(device: device)

        XCTAssertEqual(result.pixelFormatName, "rgba16Float")
        XCTAssertEqual(result.samples.count, MacEDRTestPatternConfiguration.reference.colorStops.count)
        for sample in result.samples {
            XCTAssertEqual(sample.actualRed, sample.expected.red, accuracy: 0.002, sample.label)
            XCTAssertEqual(sample.actualGreen, sample.expected.green, accuracy: 0.002, sample.label)
            XCTAssertEqual(sample.actualBlue, sample.expected.blue, accuracy: 0.002, sample.label)
        }
        XCTAssertTrue(result.samples.contains { $0.actualRed > 1 || $0.actualGreen > 1 || $0.actualBlue > 1 })
    }

    @MainActor
    func testMTKViewRequestsFP16ExtendedLinearSRGBEDRLayer() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal is unavailable on this test host.")
        }
        let view = MTKView(frame: NSRect(x: 0, y: 0, width: 64, height: 64), device: device)

        let renderer = try MacEDRMetalRenderer(view: view)
        let metalLayer = try XCTUnwrap(view.layer as? CAMetalLayer)

        XCTAssertEqual(view.colorPixelFormat, .rgba16Float)
        XCTAssertEqual(metalLayer.pixelFormat, .rgba16Float)
        XCTAssertEqual(metalLayer.colorspace?.name, CGColorSpace.extendedLinearSRGB)
        XCTAssertTrue(metalLayer.wantsExtendedDynamicRangeContent)
        XCTAssertFalse(renderer.configuration.acceptsVideoFrames)
    }

    func testRendererRejectsConfigurationThatMisstatesTheFixedPixelFormat() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal is unavailable on this test host.")
        }
        var configuration = MacEDRTestPatternConfiguration.reference
        configuration.pixelFormatName = "bgra8Unorm"

        XCTAssertThrowsError(
            try MacEDRMetalReadbackValidator.render(configuration: configuration, device: device)
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("must be rgba16Float"))
        }
    }
}
