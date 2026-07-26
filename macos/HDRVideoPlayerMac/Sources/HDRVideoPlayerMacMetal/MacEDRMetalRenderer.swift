import CoreGraphics
import Foundation
import HDRVideoPlayerMacCore
import Metal
import MetalKit
import QuartzCore

public enum MacEDRMetalError: LocalizedError {
    case noMetalDevice
    case shaderCompilation(String)
    case pipelineCreation(String)
    case bufferCreation
    case textureCreation
    case commandCreation
    case renderEncoding
    case commandFailure(String)
    case synchronizationEncoding
    case metalLayerUnavailable
    case colorSpaceUnavailable
    case unsupportedConfiguration(String)

    public var errorDescription: String? {
        switch self {
        case .noMetalDevice:
            return "No Metal device is available."
        case .shaderCompilation(let detail):
            return "Metal shader compilation failed: \(detail)"
        case .pipelineCreation(let detail):
            return "Metal render pipeline creation failed: \(detail)"
        case .bufferCreation:
            return "Metal color-stop buffer creation failed."
        case .textureCreation:
            return "Metal readback texture creation failed."
        case .commandCreation:
            return "Metal command creation failed."
        case .renderEncoding:
            return "Metal render encoding failed."
        case .commandFailure(let detail):
            return "Metal command execution failed: \(detail)"
        case .synchronizationEncoding:
            return "Metal managed-resource synchronization encoding failed."
        case .metalLayerUnavailable:
            return "The MTKView does not expose a CAMetalLayer."
        case .colorSpaceUnavailable:
            return "The extended-linear-sRGB color space is unavailable."
        case .unsupportedConfiguration(let detail):
            return "Unsupported static EDR configuration: \(detail)"
        }
    }
}

public struct MacEDRReadbackSample: Equatable, Sendable {
    public var label: String
    public var expected: MacEDRColorStop
    public var actualRed: Float
    public var actualGreen: Float
    public var actualBlue: Float

    public init(
        label: String,
        expected: MacEDRColorStop,
        actualRed: Float,
        actualGreen: Float,
        actualBlue: Float
    ) {
        self.label = label
        self.expected = expected
        self.actualRed = actualRed
        self.actualGreen = actualGreen
        self.actualBlue = actualBlue
    }
}

public enum MacEDRReadbackStorageMode: String, Equatable, Sendable {
    case shared
    case managed
}

public struct MacEDRReadbackResourcePolicy: Equatable, Sendable {
    public var storageMode: MacEDRReadbackStorageMode
    public var requiresSynchronization: Bool

    public init(storageMode: MacEDRReadbackStorageMode, requiresSynchronization: Bool) {
        self.storageMode = storageMode
        self.requiresSynchronization = requiresSynchronization
    }
}

public enum MacEDRReadbackPolicy {
    public static func make(hasUnifiedMemory: Bool) -> MacEDRReadbackResourcePolicy {
        if hasUnifiedMemory {
            return MacEDRReadbackResourcePolicy(
                storageMode: .shared,
                requiresSynchronization: false
            )
        }
        return MacEDRReadbackResourcePolicy(
            storageMode: .managed,
            requiresSynchronization: true
        )
    }
}

public struct MacEDRReadbackResult: Equatable, Sendable {
    public var deviceName: String
    public var hasUnifiedMemory: Bool
    public var storageMode: MacEDRReadbackStorageMode
    public var synchronizationPerformed: Bool
    public var pixelFormatName: String
    public var samples: [MacEDRReadbackSample]

    public init(
        deviceName: String,
        hasUnifiedMemory: Bool,
        storageMode: MacEDRReadbackStorageMode,
        synchronizationPerformed: Bool,
        pixelFormatName: String,
        samples: [MacEDRReadbackSample]
    ) {
        self.deviceName = deviceName
        self.hasUnifiedMemory = hasUnifiedMemory
        self.storageMode = storageMode
        self.synchronizationPerformed = synchronizationPerformed
        self.pixelFormatName = pixelFormatName
        self.samples = samples
    }
}

public enum MacEDRRenderState: Equatable, Sendable {
    case configured
    case submitted
    case completed
    case failed(String)

    public var diagnosticValue: String {
        switch self {
        case .configured:
            return "configured"
        case .submitted:
            return "submitted"
        case .completed:
            return "completed"
        case .failed:
            return "failed"
        }
    }

    public var failureDescription: String? {
        guard case .failed(let detail) = self else {
            return nil
        }
        return detail
    }
}

public enum MacEDRCommandCompletionOutcome: Equatable, Sendable {
    case completed
    case failed(String?)
}

public enum MacEDRRenderStateReducer {
    public static func reduce(_ outcome: MacEDRCommandCompletionOutcome) -> MacEDRRenderState {
        switch outcome {
        case .completed:
            return .completed
        case .failed(let detail):
            let boundedDetail = detail?.trimmingCharacters(in: .whitespacesAndNewlines)
            return .failed(
                boundedDetail.flatMap { $0.isEmpty ? nil : $0 }
                    ?? "Metal command buffer completed with an unknown failure."
            )
        }
    }
}

private let shaderSource = """
#include <metal_stdlib>
using namespace metal;

struct VertexOutput {
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex VertexOutput edrPatternVertex(uint vertexID [[vertex_id]]) {
    const float2 positions[6] = {
        float2(-1.0, -1.0), float2(1.0, -1.0), float2(-1.0, 1.0),
        float2(-1.0, 1.0), float2(1.0, -1.0), float2(1.0, 1.0)
    };
    const float2 textureCoordinates[6] = {
        float2(0.0, 1.0), float2(1.0, 1.0), float2(0.0, 0.0),
        float2(0.0, 0.0), float2(1.0, 1.0), float2(1.0, 0.0)
    };

    VertexOutput output;
    output.position = float4(positions[vertexID], 0.0, 1.0);
    output.textureCoordinate = textureCoordinates[vertexID];
    return output;
}

fragment float4 edrPatternFragment(
    VertexOutput input [[stage_in]],
    constant float4 *colorStops [[buffer(0)]],
    constant uint &colorStopCount [[buffer(1)]]) {
    const float boundedX = clamp(input.textureCoordinate.x, 0.0, 0.999999);
    const uint index = min(uint(boundedX * float(colorStopCount)), colorStopCount - 1);
    return colorStops[index];
}
"""

private final class MacEDRMetalPipeline {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let renderPipeline: MTLRenderPipelineState
    let colorStopBuffer: MTLBuffer
    let colorStopCount: UInt32

    init(device: MTLDevice, configuration: MacEDRTestPatternConfiguration) throws {
        guard configuration.pixelFormatName == "rgba16Float" else {
            throw MacEDRMetalError.unsupportedConfiguration(
                "pixel format must be rgba16Float"
            )
        }
        guard configuration.colorSpaceName == "extendedLinearSRGB" else {
            throw MacEDRMetalError.unsupportedConfiguration(
                "color space must be extendedLinearSRGB"
            )
        }
        guard !configuration.colorStops.isEmpty else {
            throw MacEDRMetalError.bufferCreation
        }
        guard let commandQueue = device.makeCommandQueue() else {
            throw MacEDRMetalError.commandCreation
        }

        let library: MTLLibrary
        do {
            library = try device.makeLibrary(source: shaderSource, options: nil)
        } catch {
            throw MacEDRMetalError.shaderCompilation(error.localizedDescription)
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "Static EDR test-pattern pipeline"
        descriptor.vertexFunction = library.makeFunction(name: "edrPatternVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "edrPatternFragment")
        descriptor.colorAttachments[0].pixelFormat = .rgba16Float

        do {
            renderPipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            throw MacEDRMetalError.pipelineCreation(error.localizedDescription)
        }

        let colorStops = configuration.colorStops.map {
            SIMD4<Float>($0.red, $0.green, $0.blue, 1)
        }
        let byteCount = MemoryLayout<SIMD4<Float>>.stride * colorStops.count
        guard let colorStopBuffer = device.makeBuffer(length: byteCount, options: .storageModeShared) else {
            throw MacEDRMetalError.bufferCreation
        }
        let destination = colorStopBuffer.contents().bindMemory(
            to: SIMD4<Float>.self,
            capacity: colorStops.count
        )
        for (index, color) in colorStops.enumerated() {
            destination[index] = color
        }
        colorStopBuffer.label = "Static EDR color stops"

        self.device = device
        self.commandQueue = commandQueue
        self.colorStopBuffer = colorStopBuffer
        self.colorStopCount = UInt32(colorStops.count)
    }

    func encode(renderPassDescriptor: MTLRenderPassDescriptor) throws -> MTLCommandBuffer {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw MacEDRMetalError.commandCreation
        }
        commandBuffer.label = "Static EDR test-pattern command"
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw MacEDRMetalError.renderEncoding
        }
        encoder.label = "Static EDR test-pattern encoder"
        encoder.setRenderPipelineState(renderPipeline)
        encoder.setFragmentBuffer(colorStopBuffer, offset: 0, index: 0)
        var count = colorStopCount
        encoder.setFragmentBytes(&count, length: MemoryLayout<UInt32>.size, index: 1)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()
        return commandBuffer
    }
}

public final class MacEDRMetalRenderer: NSObject, MTKViewDelegate {
    public let configuration: MacEDRTestPatternConfiguration
    public private(set) var renderState: MacEDRRenderState = .configured
    public private(set) var lastErrorDescription: String?
    public var onRenderStateChange: ((MacEDRRenderState) -> Void)? {
        didSet {
            onRenderStateChange?(renderState)
        }
    }

    private let pipeline: MacEDRMetalPipeline

    public init(
        view: MTKView,
        configuration: MacEDRTestPatternConfiguration = .reference
    ) throws {
        guard let device = view.device ?? MTLCreateSystemDefaultDevice() else {
            throw MacEDRMetalError.noMetalDevice
        }

        self.configuration = configuration
        self.pipeline = try MacEDRMetalPipeline(device: device, configuration: configuration)
        super.init()

        view.device = device
        view.colorPixelFormat = .rgba16Float
        view.clearColor = MTLClearColorMake(0, 0, 0, 1)
        view.framebufferOnly = true
        view.autoResizeDrawable = true
        view.enableSetNeedsDisplay = true
        view.isPaused = true
        view.delegate = self
        view.wantsLayer = true

        guard let metalLayer = view.layer as? CAMetalLayer else {
            throw MacEDRMetalError.metalLayerUnavailable
        }
        guard let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB) else {
            throw MacEDRMetalError.colorSpaceUnavailable
        }
        metalLayer.pixelFormat = .rgba16Float
        metalLayer.colorspace = colorSpace
        metalLayer.wantsExtendedDynamicRangeContent = configuration.requestsExtendedDynamicRange
    }

    public func draw(in view: MTKView) {
        guard
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable
        else {
            return
        }

        do {
            let commandBuffer = try pipeline.encode(renderPassDescriptor: renderPassDescriptor)
            commandBuffer.present(drawable)
            publish(.submitted)
            commandBuffer.addCompletedHandler { [weak self] completedBuffer in
                let outcome: MacEDRCommandCompletionOutcome
                if completedBuffer.status == .completed {
                    outcome = .completed
                } else {
                    let detail = completedBuffer.error?.localizedDescription
                        ?? "Metal command buffer ended with status \(completedBuffer.status.rawValue)."
                    outcome = .failed(detail)
                }
                let state = MacEDRRenderStateReducer.reduce(outcome)
                DispatchQueue.main.async { [weak self] in
                    self?.publish(state)
                }
            }
            commandBuffer.commit()
        } catch {
            publish(.failed(error.localizedDescription))
        }
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        view.setNeedsDisplay(view.bounds)
    }

    private func publish(_ state: MacEDRRenderState) {
        renderState = state
        lastErrorDescription = state.failureDescription
        onRenderStateChange?(state)
    }
}

public enum MacEDRMetalReadbackValidator {
    public static func render(
        configuration: MacEDRTestPatternConfiguration = .reference,
        device: MTLDevice? = MTLCreateSystemDefaultDevice()
    ) throws -> MacEDRReadbackResult {
        guard let device else {
            throw MacEDRMetalError.noMetalDevice
        }

        let stripeWidth = 8
        let height = 4
        let width = stripeWidth * configuration.colorStops.count
        let readbackPolicy = MacEDRReadbackPolicy.make(hasUnifiedMemory: device.hasUnifiedMemory)
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.storageMode = readbackPolicy.storageMode.metalStorageMode
        textureDescriptor.usage = [.renderTarget]
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            throw MacEDRMetalError.textureCreation
        }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)

        let pipeline = try MacEDRMetalPipeline(device: device, configuration: configuration)
        let commandBuffer = try pipeline.encode(renderPassDescriptor: renderPassDescriptor)
        let storageMode = try MacEDRReadbackStorageMode(textureStorageMode: texture.storageMode)
        var synchronizationPerformed = false
        if storageMode == .managed {
            guard let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
                throw MacEDRMetalError.synchronizationEncoding
            }
            blitEncoder.label = "Static EDR managed readback synchronization"
            blitEncoder.synchronize(resource: texture)
            blitEncoder.endEncoding()
            synchronizationPerformed = true
        }
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        guard commandBuffer.status == .completed else {
            throw MacEDRMetalError.commandFailure(
                commandBuffer.error?.localizedDescription ?? "unknown command-buffer error"
            )
        }

        let samples = configuration.colorStops.enumerated().map { index, expected in
            var components = [UInt16](repeating: 0, count: 4)
            texture.getBytes(
                &components,
                bytesPerRow: MemoryLayout<UInt16>.size * 4,
                from: MTLRegionMake2D(index * stripeWidth + stripeWidth / 2, height / 2, 1, 1),
                mipmapLevel: 0
            )
            return MacEDRReadbackSample(
                label: expected.label,
                expected: expected,
                actualRed: Float(Float16(bitPattern: components[0])),
                actualGreen: Float(Float16(bitPattern: components[1])),
                actualBlue: Float(Float16(bitPattern: components[2]))
            )
        }

        return MacEDRReadbackResult(
            deviceName: device.name,
            hasUnifiedMemory: device.hasUnifiedMemory,
            storageMode: storageMode,
            synchronizationPerformed: synchronizationPerformed,
            pixelFormatName: configuration.pixelFormatName,
            samples: samples
        )
    }
}

private extension MacEDRReadbackStorageMode {
    var metalStorageMode: MTLStorageMode {
        switch self {
        case .shared:
            return .shared
        case .managed:
            return .managed
        }
    }

    init(textureStorageMode: MTLStorageMode) throws {
        switch textureStorageMode {
        case .shared:
            self = .shared
        case .managed:
            self = .managed
        default:
            throw MacEDRMetalError.unsupportedConfiguration(
                "CPU readback does not support texture storage mode \(textureStorageMode.rawValue)"
            )
        }
    }
}
