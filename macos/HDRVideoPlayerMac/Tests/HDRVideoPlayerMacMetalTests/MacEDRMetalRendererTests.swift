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

        XCTAssertEqual(result.hasUnifiedMemory, device.hasUnifiedMemory)
        XCTAssertEqual(
            result.storageMode,
            device.hasUnifiedMemory ? .shared : .managed
        )
        XCTAssertEqual(result.synchronizationPerformed, result.storageMode == .managed)
        XCTAssertEqual(result.pixelFormatName, "rgba16Float")
        XCTAssertEqual(result.samples.count, MacEDRTestPatternConfiguration.reference.colorStops.count)
        for sample in result.samples {
            XCTAssertEqual(sample.actualRed, sample.expected.red, accuracy: 0.002, sample.label)
            XCTAssertEqual(sample.actualGreen, sample.expected.green, accuracy: 0.002, sample.label)
            XCTAssertEqual(sample.actualBlue, sample.expected.blue, accuracy: 0.002, sample.label)
        }
        XCTAssertTrue(result.samples.contains { $0.actualRed > 1 || $0.actualGreen > 1 || $0.actualBlue > 1 })
        let maximumActualComponent = try XCTUnwrap(
            result.samples
                .flatMap { [$0.actualRed, $0.actualGreen, $0.actualBlue] }
                .max()
        )
        XCTAssertEqual(maximumActualComponent, Float(4.0), accuracy: Float(0.002))
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

    func testReadbackPolicyUsesSharedMemoryWithoutSynchronizationForUnifiedDevices() {
        let policy = MacEDRReadbackPolicy.make(hasUnifiedMemory: true)

        XCTAssertEqual(policy.storageMode, .shared)
        XCTAssertFalse(policy.requiresSynchronization)
    }

    func testReadbackPolicyUsesManagedMemoryWithSynchronizationForDiscreteDevices() {
        let policy = MacEDRReadbackPolicy.make(hasUnifiedMemory: false)

        XCTAssertEqual(policy.storageMode, .managed)
        XCTAssertTrue(policy.requiresSynchronization)
    }

    func testRenderStateReducerMapsCompletionAndBoundedFailures() {
        XCTAssertEqual(MacEDRRenderStateReducer.reduce(.completed), .completed)
        XCTAssertEqual(
            MacEDRRenderStateReducer.reduce(.failed("GPU timeout")),
            .failed("GPU timeout")
        )
        XCTAssertEqual(
            MacEDRRenderStateReducer.reduce(.failed("  ")),
            .failed("Metal command buffer completed with an unknown failure.")
        )
    }

    @MainActor
    func testRendererPublishesConfiguredStateWhenObserverIsAttached() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw XCTSkip("Metal is unavailable on this test host.")
        }
        let view = MTKView(frame: NSRect(x: 0, y: 0, width: 64, height: 64), device: device)
        let renderer = try MacEDRMetalRenderer(view: view)
        var observedState: MacEDRRenderState?
        var observedOnMainThread = false

        renderer.onRenderStateChange = { state in
            observedState = state
            observedOnMainThread = Thread.isMainThread
        }

        XCTAssertEqual(observedState, .configured)
        XCTAssertTrue(observedOnMainThread)
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
