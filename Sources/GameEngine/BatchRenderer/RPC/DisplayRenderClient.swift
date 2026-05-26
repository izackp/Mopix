//
//  DisplayRenderClient.swift
//
//
//  Synchronous-feeling facade for game code that renders through DisplayClient.
//

import Foundation
import SDL2
import SDL2Swift

public final class DisplayRenderClient: IDraw {
    public let displayClient: DisplayClient
    public var defaultTime: UInt64 = 0
    public var windowSize: Size<Int16>

    private var cmdList: [DrawCmd] = []
    private var deliveryChain: Task<Void, Never>? = nil
    private var errorForId: [UInt64: Error] = [:]

    public init(displayClient: DisplayClient, windowSize: Size<Int16>) {
        self.displayClient = displayClient
        self.windowSize = windowSize
    }

    public func draw(
        _ id: UInt64,
        _ resourceId: UInt64,
        _ rect: Rect<Int>,
        _ color: SDLColor = .white,
        _ z: Int = 1,
        _ rotation: Float = 0,
        _ rotationPoint: Point<Int> = .zero,
        _ alpha: Float = 1,
        _ clipping: Rect<Int> = .zero,
        _ relTime: UInt64 = 0
    ) {
        let time = relTime + defaultTime
        let cmd = DrawCmd(
            animationId: id,
            parentAnimationId: 0,
            dest: rect,
            color: color,
            alpha: alpha,
            z: z,
            rotation: rotation,
            rotationPoint: rotationPoint,
            clippingRect: clipping,
            flip: [],
            time: time,
            type: .image(resourceId: resourceId)
        )
        cmdList.append(cmd)
    }

    public func drawCmd(_ cmd: DrawCmd) {
        cmdList.append(cmd)
    }

    public func createImage(_ block: (_ context: IDraw) throws -> (), size: Size<DValue>) throws -> UInt64 {
        try displayClient.createImage(block, size: size)
    }

    public func loadResource(_ url: VDUrl) throws -> ImageFlyWeight {
        let preferredHandle = Xoroshiro.shared.randomBytes()
        let flyweight = ImageFlyWeight(id: preferredHandle)
        Task { [weak self] in
            guard let self else { return }
            do {
                let body = try await self.displayClient.loadResource(
                    url: url,
                    kind: .image,
                    density: 1.0,
                    preferredHandle: preferredHandle
                )
                if case let .image(handle, _) = body {
                    flyweight._id = handle
                }
            } catch {
                await MainActor.run {
                    self.errorForId[preferredHandle] = error
                }
            }
        }
        return flyweight
    }

    public func loadResources(_ urls: [VDUrl]) throws -> [ImageFlyWeight] {
        urls.map { try! loadResource($0) }
    }

    public func unloadResources(_ resources: [ImageResource]) {
        for resource in resources {
            Task { [displayClient] in
                await displayClient.releaseResource(handle: resource.id)
            }
        }
    }

    public func clearCommands() {
        cmdList.removeAll(keepingCapacity: true)
    }

    @discardableResult
    public func sendCommands() -> Task<Void, Never> {
        let cmds = cmdList
        let prev = deliveryChain
        let clientTick = defaultTime
        let task = Task {
            await prev?.value
            guard !cmds.isEmpty else { return }
            for cmd in cmds {
                await self.displayClient.drawCmd(cmd)
            }
            await self.displayClient.sendFrameAndWait(clientTick: clientTick)
        }
        deliveryChain = task
        return task
    }

    public func updateLogicalSize(_ size: Size<Int16>) {
        windowSize = size
        Task { [displayClient] in
            try? await displayClient.setDisplayConfig(
                logicalSize: Size(Int(size.width), Int(size.height)),
                scale: 1
            )
        }
    }
}
