//
//  DisplayRenderClient.swift
//
//
//  Synchronous-feeling facade for game code that renders through DisplayClient.
//

import Foundation
import SDL2
import SDL2Swift

public struct QueuedUnload {
    let resource: ImageResource
    var ticks: Int
}

public final class DisplayRenderClient: IDraw {
    public let displayClient: DisplayClient
    public var defaultTime: UInt64 = 0
    public var windowSize: Size<Int16>
    public var maxTicksForRollback = 10

    /// When set, `sendCommands()` delivers synchronously via this closure instead of
    /// going through the async actor/transport stack. Set by `FullWindow` for in-process use.
    /// Always called from the main actor; `nonisolated(unsafe)` because `DisplayRenderClient`
    /// itself is not actor-isolated, but callers guarantee main-actor context.
    nonisolated(unsafe) public var inProcessSendFrame: ((_ clientTick: UInt64, _ cmds: [DrawCmd]) -> Void)?

    private var cmdList: [DrawCmd] = []
    private var deliveryChain: Task<Void, Never>? = nil
    private var errorForId: [UInt64: Error] = [:]
    private var cacheList = WeakArray<IResourceCache>()
    private var _toUnload: [QueuedUnload] = []

    public init(displayClient: DisplayClient, windowSize: Size<Int16>) {
        self.displayClient = displayClient
        self.windowSize = windowSize
    }

    // MARK: - IResourceCache management

    public func addResourceCache(_ cache: any IResourceCache) throws {
        cacheList.append(cache)
        try cache.loadResources(self)
        cacheList.clean()
    }

    public func removeResourceCache(_ cache: any IResourceCache) {
        cacheList.remove(element: cache)
        cache.unloadResources(self)
        cacheList.clean()
    }

    func reloadCache() throws {
        cacheList.clean()
        for eachItem in cacheList {
            eachItem?.invalidateCache(self)
            try eachItem?.loadResources(self)
        }
    }

    // MARK: - IDraw

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

    // MARK: - Resource loading

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
        try urls.map { try loadResource($0) }
    }

    public func loadResource(_ image: EditableImage) throws -> UInt64 {
        let preferredHandle = Xoroshiro.shared.randomBytes()
        image.id = preferredHandle
        let size = image.size()
        let bytes = try image.withPixelData { Array($0.ptr) }
        let syntheticUrl = URL(string: "memory://editable/\(preferredHandle)")!
        Task { [weak self] in
            guard let self else { return }
            do {
                let body = try await self.displayClient.uploadRawPixels(
                    url: syntheticUrl,
                    size: size,
                    data: bytes,
                    preferredHandle: preferredHandle
                )
                if case let .image(handle, _) = body {
                    image.id = handle
                }
            } catch {
                await MainActor.run {
                    self.errorForId[preferredHandle] = error
                }
            }
        }
        return preferredHandle
    }

    public func updateImage(_ id: UInt64, _ image: EditableImage) throws {
        let size = image.size()
        let bytes = try image.withPixelData { Array($0.ptr) }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.displayClient.updateResource(handle: id, size: size, data: bytes)
            } catch {
                await MainActor.run {
                    self.errorForId[id] = error
                }
            }
        }
    }

    // MARK: - Resource unloading

    public func unloadResources(_ resources: [ImageResource]) {
        for resource in resources {
            Task { [displayClient] in
                await displayClient.releaseResource(handle: resource.id)
            }
        }
    }

    public func unloadResourceDelayed(_ id: ImageResource, _ ticks: Int) {
        _toUnload.append(QueuedUnload(resource: id, ticks: ticks))
    }

    public func unloadResourcesDelayed(_ idList: [ImageResource], _ ticks: Int) {
        for each in idList {
            _toUnload.append(QueuedUnload(resource: each, ticks: ticks))
        }
    }

    // MARK: - Frame

    public func clearCommands() {
        cmdList.removeAll(keepingCapacity: true)
    }

    @discardableResult
    public func sendCommands() -> Task<Void, Never> {
        // Tick down delayed unloads and fire expired ones
        _toUnload.forEachUncheckedMut { item, _ in item.ticks -= 1 }
        let expired = _toUnload.filter { $0.ticks <= 0 }.map { $0.resource }
        _toUnload.removeAll(where: { $0.ticks <= 0 })
        if !expired.isEmpty {
            unloadResources(expired)
        }

        let cmds = cmdList
        let clientTick = defaultTime

        // Sync in-process path: deliver directly on the caller's (main) actor.
        // Returns a no-op Task so callers that await the result still compile.
        if let inProcessSendFrame {
            inProcessSendFrame(clientTick, cmds)
            return Task {}
        }

        // Async path for remote transport
        let prev = deliveryChain
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
