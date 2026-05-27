//
//  DisplayServer.swift
//
//
//  Server-side Display RPC implementation built on top of RendererServer.
//

import Foundation
import SDL2
import SDL2Swift
import SDL2_TTFSwift

@MainActor
public final class DisplayServer {
    private struct MountedPack {
        let ownerClientId: ClientId
        let rootURL: URL
    }

    private enum ResourceOrigin {
        case pack(url: VDUrl, kind: ResourceKind, density: Float)
        case uploaded(url: VDUrl, kind: ResourceKind)
        case generated(kind: ResourceKind)
    }

    private struct FontResource {
        let ownerClientId: ClientId
        let family: String
        let url: VDUrl?
        let uploadedData: [UInt8]?
    }

    private struct SoundResource {
        let ownerClientId: ClientId
        let url: VDUrl?
        let uploadedData: [UInt8]?
    }

    private struct PendingRelease {
        let ownerClientId: ClientId
        let expiresAt: UInt64
    }

    private enum ProceduralBase {
        case blank(Size<Int>)
        case copy(ResHandle)
    }

    private struct ProceduralImage {
        let ownerClientId: ClientId
        var base: ProceduralBase
        var journal: [DrawCmd]
    }

    public let rendererServer: RendererServer
    public let virtualDrive: VirtualDrive
    public let window: SDLWindow?

    private let tempDirectory: URL
    private var nextClientId: ClientId = 1

    private var clientsByTransport: [ObjectIdentifier: ClientState] = [:]
    private var transports: [ObjectIdentifier: any DisplayTransport] = [:]

    private var resourceOwners: [ResHandle: ClientId] = [:]
    private var resourceOrigins: [ResHandle: ResourceOrigin] = [:]
    private var fontResources: [ResHandle: FontResource] = [:]
    private var soundResources: [ResHandle: SoundResource] = [:]
    private var lingeringResources: [ResHandle: PendingRelease] = [:]
    private var mountedPacks: [String: MountedPack] = [:]
    private var proceduralImages: [ResHandle: ProceduralImage] = [:]

    public init(
        rendererServer: RendererServer,
        window: SDLWindow? = nil,
        virtualDrive: VirtualDrive = .shared,
        tempDirectory: URL = FileManager.default.temporaryDirectory
    ) {
        self.rendererServer = rendererServer
        self.window = window
        self.virtualDrive = virtualDrive
        self.tempDirectory = tempDirectory
    }

    public func bind(_ transport: any DisplayTransport) {
        let key = ObjectIdentifier(transport)
        transports[key] = transport

        if let endpoint = transport as? InProcessTransport.ServerEnd {
            endpoint.handler = { [weak self, weak endpoint] message in
                guard let self, let endpoint else { return }
                await self.handle(message, from: endpoint)
            }
        }
    }

    public func handle(_ message: ClientMessage, from transport: any DisplayTransport) async {
        bind(transport)
        collectExpiredResources()

        switch message {
        case let .connect(requestId, name, version, logicalSize, resourceLingerMs):
            await handleConnect(
                requestId: requestId,
                name: name,
                version: version,
                logicalSize: logicalSize,
                resourceLingerMs: resourceLingerMs,
                transport: transport
            )

        case .disconnect:
            handleDisconnect(transport: transport)

        case let .ping(requestId, _):
            await withClient(requestId: requestId, transport: transport) { _ in
                await self.sendResponse(
                    requestId,
                    via: transport,
                    status: .ok,
                    body: .pong(serverTick: SDL_GetTicks64())
                )
            }

        case let .setDisplayConfig(requestId, logicalSize, scale):
            await withClient(requestId: requestId, transport: transport) { client in
                guard logicalSize.width > 0, logicalSize.height > 0, scale > 0 else {
                    await self.sendError(requestId, via: transport, status: .badRequest, detail: "logicalSize and scale must be positive")
                    return
                }
                client.logicalSize = logicalSize
                client.scale = scale
                self.rebuildCombinedViewportCommands()
                await self.sendResponse(requestId, via: transport, status: .ok)
            }

        case let .setWindowConfig(requestId, config):
            await withClient(requestId: requestId, transport: transport) { _ in
                do {
                    try self.applyWindowConfig(config)
                    await self.sendResponse(requestId, via: transport, status: .ok)
                } catch {
                    await self.sendError(requestId, via: transport, status: .serverError, detail: error.localizedDescription)
                }
            }

        case let .uploadPack(requestId, name, data):
            await withClient(requestId: requestId, transport: transport) { client in
                do {
                    try self.uploadPack(name: name, data: data, client: client)
                    await self.sendResponse(requestId, via: transport, status: .ok)
                } catch let error as DisplayServerError {
                    await self.sendError(requestId, via: transport, status: error.status, detail: error.message)
                } catch {
                    await self.sendError(requestId, via: transport, status: .serverError, detail: error.localizedDescription)
                }
            }

        case let .loadResource(requestId, url, kind, density, preferredHandle):
            await withClient(requestId: requestId, transport: transport) { client in
                do {
                    let body = try self.loadResource(url: url, kind: kind, density: density, preferredHandle: preferredHandle, client: client)
                    await self.sendResponse(requestId, via: transport, status: .ok, body: body)
                } catch let error as DisplayServerError {
                    await self.sendError(requestId, via: transport, status: error.status, detail: error.message)
                } catch {
                    await self.sendError(requestId, via: transport, status: .serverError, detail: error.localizedDescription)
                }
            }

        case let .uploadResource(requestId, url, kind, _, data, preferredHandle):
            await withClient(requestId: requestId, transport: transport) { client in
                do {
                    let body = try self.uploadResource(url: url, kind: kind, data: data, preferredHandle: preferredHandle, client: client)
                    await self.sendResponse(requestId, via: transport, status: .ok, body: body)
                } catch let error as DisplayServerError {
                    await self.sendError(requestId, via: transport, status: error.status, detail: error.message)
                } catch {
                    await self.sendError(requestId, via: transport, status: .serverError, detail: error.localizedDescription)
                }
            }

        case let .requestPixelData(requestId, handle):
            await withClient(requestId: requestId, transport: transport) { client in
                do {
                    let body = try self.requestPixelData(handle: handle, client: client)
                    await self.sendResponse(requestId, via: transport, status: .ok, body: body)
                } catch let error as DisplayServerError {
                    await self.sendError(requestId, via: transport, status: error.status, detail: error.message)
                } catch {
                    await self.sendError(requestId, via: transport, status: .serverError, detail: error.localizedDescription)
                }
            }

        case let .uploadRawPixels(requestId, url, size, data, preferredHandle):
            await withClient(requestId: requestId, transport: transport) { client in
                do {
                    let body = try self.uploadRawPixels(url: url, size: size, data: data, preferredHandle: preferredHandle, client: client)
                    await self.sendResponse(requestId, via: transport, status: .ok, body: body)
                } catch let error as DisplayServerError {
                    await self.sendError(requestId, via: transport, status: error.status, detail: error.message)
                } catch {
                    await self.sendError(requestId, via: transport, status: .serverError, detail: error.localizedDescription)
                }
            }

        case let .updateResource(requestId, handle, size, data):
            await withClient(requestId: requestId, transport: transport) { client in
                do {
                    try self.updateResource(handle: handle, size: size, data: data, client: client)
                    await self.sendResponse(requestId, via: transport, status: .ok)
                } catch let error as DisplayServerError {
                    await self.sendError(requestId, via: transport, status: error.status, detail: error.message)
                } catch {
                    await self.sendError(requestId, via: transport, status: .serverError, detail: error.localizedDescription)
                }
            }

        case let .releaseResource(handle):
            guard let client = client(for: transport) else { return }
            releaseResource(handle: handle, client: client)

        case let .sendFrame(clientTick, compositions, cmds):
            guard let client = client(for: transport) else { return }
            await handleSendFrame(clientTick: clientTick, compositions: compositions, cmds: cmds, client: client, transport: transport)

        case let .screenshot(requestId):
            await withClient(requestId: requestId, transport: transport) { _ in
                do {
                    let body = try self.screenshotBody()
                    await self.sendResponse(requestId, via: transport, status: .ok, body: body)
                } catch {
                    await self.sendError(requestId, via: transport, status: .serverError, detail: error.localizedDescription)
                }
            }

        case let .playSound(requestId, _, _):
            await withClient(requestId: requestId, transport: transport) { _ in
                await self.sendError(requestId, via: transport, status: .serverError, detail: "audio not yet implemented")
            }

        case .stopSound, .pauseSound, .resumeSound, .updateSound, .stopAllSounds:
            break
        }
    }
}

private extension DisplayServer {
    enum DisplayServerError: Error {
        case badRequest(String)
        case notFound(String)
        case conflict(String)
        case server(String)

        var status: ResponseStatus {
            switch self {
            case .badRequest:
                return .badRequest
            case .notFound:
                return .notFound
            case .conflict:
                return .conflict
            case .server:
                return .serverError
            }
        }

        var message: String {
            switch self {
            case let .badRequest(message),
                 let .notFound(message),
                 let .conflict(message),
                 let .server(message):
                return message
            }
        }
    }

    func client(for transport: any DisplayTransport) -> ClientState? {
        clientsByTransport[ObjectIdentifier(transport)]
    }

    func withClient(
        requestId: RequestId,
        transport: any DisplayTransport,
        _ body: (ClientState) async -> Void
    ) async {
        guard let client = client(for: transport) else {
            await sendError(requestId, via: transport, status: .badRequest, detail: "unknown client")
            return
        }
        await body(client)
    }

    func sendResponse(
        _ requestId: RequestId,
        via transport: any DisplayTransport,
        status: ResponseStatus,
        body: ResponseBody? = nil
    ) async {
        await transport.send(.response(Response(requestId: requestId, status: status, body: body)))
    }

    func sendError(
        _ requestId: RequestId,
        via transport: any DisplayTransport,
        status: ResponseStatus,
        detail: String
    ) async {
        await sendResponse(requestId, via: transport, status: status, body: .errorDetail(detail))
    }

    func sendEvent(_ event: ServerEvent, to transport: any DisplayTransport) async {
        await transport.send(.event(event))
    }

    func handleConnect(
        requestId: RequestId,
        name: String,
        version: UInt32,
        logicalSize: Size<Int>,
        resourceLingerMs: UInt32,
        transport: any DisplayTransport
    ) async {
        guard logicalSize.width > 0, logicalSize.height > 0 else {
            await sendError(requestId, via: transport, status: .badRequest, detail: "logicalSize must be positive")
            return
        }
        let key = ObjectIdentifier(transport)
        guard clientsByTransport[key] == nil else {
            await sendError(requestId, via: transport, status: .conflict, detail: "client already connected")
            return
        }

        let clientId = nextClientId
        nextClientId += 1

        clientsByTransport[key] = ClientState(
            clientId: clientId,
            name: name,
            version: version,
            logicalSize: logicalSize,
            resourceLingerMs: resourceLingerMs
        )

        recalculateViewports()
        rebuildCombinedViewportCommands()

        await sendResponse(requestId, via: transport, status: .ok)
        await sendViewportChanges()
    }

    func handleDisconnect(transport: any DisplayTransport) {
        let key = ObjectIdentifier(transport)
        guard let client = clientsByTransport.removeValue(forKey: key) else {
            return
        }

        client.rawViewportCommands = []
        virtualDrive.packages.removeAll { mounted in
            guard let pack = mountedPacks[mounted.meta.name] else { return false }
            return pack.ownerClientId == client.clientId
        }

        for packName in client.packNames {
            if let mounted = mountedPacks.removeValue(forKey: packName) {
                try? FileManager.default.removeItem(at: mounted.rootURL)
            }
        }

        for handle in client.ownedResources {
            freeResource(handle)
        }

        lingeringResources = lingeringResources.filter { _, pending in
            pending.ownerClientId != client.clientId
        }

        recalculateViewports()
        rebuildCombinedViewportCommands()
        Task { await self.sendViewportChanges() }
    }

    func applyWindowConfig(_ config: WindowConfig) throws {
        guard let window else {
            throw DisplayServerError.server("window configuration unavailable")
        }
        window.title = config.title
        try rendererServer.renderer.setVSync(value: config.vsync)

        let fullscreenFlag: UInt32 = config.fullscreen
            ? UInt32(SDL_WINDOW_FULLSCREEN_DESKTOP.rawValue)
            : 0
        guard SDL_SetWindowFullscreen(window.getPtr(), fullscreenFlag) == 0 else {
            throw GenericError(String(cString: SDL_GetError()))
        }
    }

    func uploadPack(name: String, data: [UInt8], client: ClientState) throws {
        guard !name.isEmpty else {
            throw DisplayServerError.badRequest("pack name cannot be empty")
        }

        let meta = (try? PackageMeta.parseMetaFromName(name)) ?? PackageMeta(name: name, version: .zero)
        let extractedRoot = try extractPack(named: name, data: data)
        let mountedDir = MountedDir(
            meta: meta,
            path: extractedRoot,
            virtualPath: String(OS.defaultPathSeparator),
            isReadOnly: false,
            isDirectory: true
        )

        if let previous = mountedPacks[name] {
            virtualDrive.packages.removeAll { $0.meta.name == meta.name }
            try? FileManager.default.removeItem(at: previous.rootURL)
        }

        virtualDrive.packages.append(mountedDir)
        mountedPacks[name] = MountedPack(ownerClientId: client.clientId, rootURL: extractedRoot)
        client.packNames.insert(name)

        hotReloadPack(named: name)
    }

    func extractPack(named name: String, data: [UInt8]) throws -> URL {
        let contentURL = tempDirectory
            .appendingPathComponent("DisplayServerPacks", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)

        if FileManager.default.fileExists(atPath: contentURL.path) {
            try FileManager.default.removeItem(at: contentURL)
        }
        try FileManager.default.createDirectory(at: contentURL, withIntermediateDirectories: true)
        try PackArchive.decode(data: data, into: contentURL)
        return contentURL
    }

    func loadResource(url: VDUrl, kind: ResourceKind, density: Float, preferredHandle: ResHandle?, client: ClientState) throws -> ResponseBody {
        switch kind {
        case .image:
            let image: Image
            if let preferredHandle {
                image = try rendererServer.resourceStore.loadResource(url, preferredHandle)
            } else {
                image = try rendererServer.resourceStore.loadResource(url)
            }
            track(handle: image.id, owner: client, origin: .pack(url: url, kind: kind, density: density))
            return .image(handle: image.id, size: image.size.to(Int.self))

        case .font:
            rendererServer.imageManager.addFont(url)
            let family = try readFontFamily(url: url)
            let handle = generateHandle()
            track(handle: handle, owner: client, origin: .pack(url: url, kind: kind, density: density))
            fontResources[handle] = FontResource(ownerClientId: client.clientId, family: family, url: url, uploadedData: nil)
            return .font(handle: handle, family: family)

        case .sound:
            throw DisplayServerError.server("audio not yet implemented")
        }
    }

    func uploadResource(url: VDUrl, kind: ResourceKind, data: [UInt8], preferredHandle: ResHandle?, client: ClientState) throws -> ResponseBody {
        switch kind {
        case .image:
            let pixelData = try pixelDataFromImageBytes(data)
            let image: ReadOnlyImage
            if let preferredHandle {
                image = try rendererServer.resourceStore.loadResource(pixelData, preferredHandle)
            } else {
                image = try rendererServer.resourceStore.loadResource(pixelData)
            }
            track(handle: image.id, owner: client, origin: .uploaded(url: url, kind: kind))
            return .image(handle: image.id, size: image.size().to(Int.self))

        case .font:
            let family = try readFontFamily(data: data, fallbackURL: url)
            let handle = generateHandle()
            track(handle: handle, owner: client, origin: .uploaded(url: url, kind: kind))
            fontResources[handle] = FontResource(ownerClientId: client.clientId, family: family, url: url, uploadedData: data)
            return .font(handle: handle, family: family)

        case .sound:
            throw DisplayServerError.server("audio not yet implemented")
        }
    }

    func uploadRawPixels(url: VDUrl, size: Size<Int>, data: [UInt8], preferredHandle: ResHandle?, client: ClientState) throws -> ResponseBody {
        let pixelData = try rawBytesToPixelData(size: size, data: data)
        let image: ReadOnlyImage
        if let preferredHandle {
            image = try rendererServer.resourceStore.loadResource(pixelData, preferredHandle)
        } else {
            image = try rendererServer.resourceStore.loadResource(pixelData)
        }
        track(handle: image.id, owner: client, origin: .uploaded(url: url, kind: .image))
        return .image(handle: image.id, size: image.size().to(Int.self))
    }

    func updateResource(handle: ResHandle, size: Size<Int>, data: [UInt8], client: ClientState) throws {
        try requireOwnership(handle: handle, client: client)
        let pixelData = try rawBytesToPixelData(size: size, data: data)
        try rendererServer.resourceStore.updateImage(handle, pixelData)
    }

    private func rawBytesToPixelData(size: Size<Int>, data: [UInt8]) throws -> PixelData {
        let pixelData = try PixelData(size)
        try pixelData.withMutablePixelData { raw in
            let copyCount = min(data.count, raw.ptr.count)
            raw.ptr.copyBytes(from: data.prefix(copyCount))
        }
        return pixelData
    }

    func requestPixelData(handle: ResHandle, client: ClientState) throws -> ResponseBody {
        try requireOwnership(handle: handle, client: client)

        guard fontResources[handle] == nil, soundResources[handle] == nil else {
            throw DisplayServerError.badRequest("pixel data is only available for image resources")
        }

        let image = try rendererServer.resourceStore.fetchResource(handle)
        let pixelData = try image.readPixelData()
        let bytes = try bytes(from: pixelData)
        return .pixelData(handle: handle, size: pixelData.size(), data: bytes)
    }

    func releaseResource(handle: ResHandle, client: ClientState) {
        guard resourceOwners[handle] == client.clientId else {
            return
        }
        let lingerMs = UInt64(client.resourceLingerMs)
        if lingerMs == 0 {
            freeResource(handle)
        } else {
            lingeringResources[handle] = PendingRelease(ownerClientId: client.clientId, expiresAt: SDL_GetTicks64() + lingerMs)
        }
    }

    func handleSendFrame(
        clientTick: UInt64,
        compositions: [CompositionCmd],
        cmds: [DrawCmd],
        client: ClientState,
        transport: any DisplayTransport
    ) async {
        for (index, composition) in compositions.enumerated() {
            do {
                try applyComposition(composition, client: client)
            } catch {
                let handle = composition.handle
                await sendEvent(
                    .compositionError(
                        clientTick: clientTick,
                        compositionIndex: index,
                        handle: handle,
                        reason: error.localizedDescription
                    ),
                    to: transport
                )
            }
        }

        var targetCommands: [ResHandle:[DrawCmd]] = [:]
        var viewportCommands: [DrawCmd] = []

        for cmd in cmds {
            do {
                try validate(command: cmd, client: client)
                if cmd.target == 0 {
                    viewportCommands.append(cmd)
                } else {
                    targetCommands[cmd.target, default: []].append(cmd)
                    if var procedural = proceduralImages[cmd.target] {
                        procedural.journal.append(cmd)
                        proceduralImages[cmd.target] = procedural
                    }
                }
            } catch {
                let handle = resourceHandle(from: cmd) ?? cmd.target
                await sendEvent(
                    .drawError(clientTick: clientTick, handle: handle, reason: error.localizedDescription),
                    to: transport
                )
            }
        }

        for (target, list) in targetCommands {
            do {
                try draw(commands: list, into: target)
            } catch {
                await sendEvent(
                    .drawError(clientTick: clientTick, handle: target, reason: error.localizedDescription),
                    to: transport
                )
            }
        }

        client.rawViewportCommands = viewportCommands
        rebuildCombinedViewportCommands()
    }

    func applyComposition(_ composition: CompositionCmd, client: ClientState) throws {
        guard !handleExists(composition.handle) else {
            throw DisplayServerError.conflict("composition handle already in use")
        }

        switch composition {
        case let .createEditableImage(handle, size):
            let pixelData = try PixelData(size)
            try setImage(handle: handle, pixelData: pixelData)
            track(handle: handle, owner: client, origin: .generated(kind: .image))
            proceduralImages[handle] = nil

        case let .createProceduralImage(handle, size):
            let pixelData = try PixelData(size)
            try setImage(handle: handle, pixelData: pixelData)
            track(handle: handle, owner: client, origin: .generated(kind: .image))
            proceduralImages[handle] = ProceduralImage(ownerClientId: client.clientId, base: .blank(size), journal: [])

        case let .copyToEditable(handle, source):
            try requireOwnership(handle: source, client: client)
            let sourceImage = try rendererServer.resourceStore.fetchResource(source)
            let pixelData = try sourceImage.readPixelData()
            try setImage(handle: handle, pixelData: pixelData)
            track(handle: handle, owner: client, origin: .generated(kind: .image))
            proceduralImages[handle] = nil

        case let .copyToProceduralImage(handle, source):
            try requireOwnership(handle: source, client: client)
            let sourceImage = try rendererServer.resourceStore.fetchResource(source)
            let pixelData = try sourceImage.readPixelData()
            try setImage(handle: handle, pixelData: pixelData)
            track(handle: handle, owner: client, origin: .generated(kind: .image))
            proceduralImages[handle] = ProceduralImage(ownerClientId: client.clientId, base: .copy(source), journal: [])
        }
    }

    func validate(command: DrawCmd, client: ClientState) throws {
        if command.target != 0 {
            try requireOwnership(handle: command.target, client: client)
        }
        if let handle = resourceHandle(from: command) {
            try requireDrawableAccess(handle: handle, client: client)
        }
    }

    func resourceHandle(from command: DrawCmd) -> ResHandle? {
        switch command.type {
        case let .image(resourceId):
            return resourceId
        case let .text(fontHandle, _, _, _):
            return fontHandle
        case .fill, .view, .line, .circle, .rect, .rtt:
            return nil
        }
    }

    func draw(commands: [DrawCmd], into target: ResHandle) throws {
        let sorted = commands.sorted { $0.z < $1.z }
        let previousTarget = rendererServer.renderer.target
        let previousClip = rendererServer.renderer.getClipRect()
        let targetImage = try rendererServer.resourceStore.fetchResource(target)
        let page = rendererServer.imageManager.atlas.listPages[targetImage.subTextureIndex.texturePageIndex]
        let targetFrame = targetImage.sourceRect.to(Int.self)

        try rendererServer.renderer.setTarget(page.texture)
        try rendererServer.renderer.setClipRect(targetFrame.sdlRect())

        var resolvedPositions: [UInt64:Rect<Int>] = [:]
        for cmd in sorted {
            let resolved = resolvedDest(cmd.dest, parentId: cmd.parentAnimationId, positions: &resolvedPositions)
            if cmd.animationId != 0 {
                resolvedPositions[cmd.animationId] = resolved
            }
            let drawRect = resolved.offset(targetFrame.origin)
            try draw(command: cmd, in: drawRect, targetFrame: targetFrame)
        }

        try rendererServer.renderer.setClipRect(previousClip)
        try rendererServer.renderer.setTarget(previousTarget)
    }

    func draw(command: DrawCmd, in dest: Rect<Int>, targetFrame: Rect<Int>) throws {
        let clipRect = effectiveClipRect(for: command.clippingRect, viewport: targetFrame)
        try rendererServer.renderer.setClipRect(clipRect.sdlRect())

        switch command.type {
        case let .image(resourceId):
            let image = try rendererServer.resourceStore.fetchResource(resourceId)
            let source = image.getTextureSlice()
            if command.rotation != 0 || command.flip.hasValue() {
                try rendererServer.renderer.draw(source, dest.sdlRect(), command.color, command.alpha, Double(command.rotation), command.rotationPoint.sdlPoint(), command.flip)
            } else {
                try rendererServer.renderer.draw(source, dest.sdlRect(), command.color, command.alpha)
            }

        case .fill:
            try drawFill(command, dest: dest)

        case let .view(borderColor, borderWidth):
            try drawView(command, borderColor: borderColor, borderWidth: borderWidth, dest: dest)

        case .text, .line, .circle, .rect, .rtt:
            break
        }
    }

    func rebuildCombinedViewportCommands() {
        var combined: [DrawCmd] = []
        let clients = clientsByTransport.values.sorted { $0.clientId < $1.clientId }
        for client in clients {
            combined.append(contentsOf: client.rawViewportCommands.map { translateViewportCommand($0, client: client) })
        }
        rendererServer.receiveCmdsSync(combined)
    }

    func translateViewportCommand(_ command: DrawCmd, client: ClientState) -> DrawCmd {
        let viewport = client.viewportFrame
        let dest = scaledRect(command.dest, scale: client.scale).offset(viewport.origin)
        let clip = effectiveClipRect(for: scaledRect(command.clippingRect, scale: client.scale).offset(viewport.origin), viewport: viewport)

        return DrawCmd(
            target: 0,
            animationId: namespacedAnimationId(command.animationId, clientId: client.clientId),
            parentAnimationId: namespacedAnimationId(command.parentAnimationId, clientId: client.clientId),
            dest: dest,
            color: command.color,
            alpha: command.alpha,
            z: command.z,
            rotation: command.rotation,
            rotationPoint: scaledPoint(command.rotationPoint, scale: client.scale),
            clippingRect: clip,
            flip: command.flip,
            time: command.time,
            type: translateDrawType(command.type, client: client)
        )
    }

    func translateDrawType(_ type: DrawCmdType, client: ClientState) -> DrawCmdType {
        switch type {
        case let .line(to, thickness):
            return .line(
                to: scaledPoint(to, scale: client.scale).offset(client.viewportFrame.origin.x, client.viewportFrame.origin.y),
                thickness: max(1, Int((Float(thickness) * client.scale).rounded()))
            )
        default:
            return type
        }
    }

    func recalculateViewports() {
        let sortedKeys = clientsByTransport.keys.sorted { lhs, rhs in
            guard let left = clientsByTransport[lhs], let right = clientsByTransport[rhs] else { return false }
            return left.clientId < right.clientId
        }
        let outputSize = rendererOutputSize()
        let frames = viewportFrames(count: sortedKeys.count, outputSize: outputSize)
        for (index, key) in sortedKeys.enumerated() {
            clientsByTransport[key]?.viewportFrame = frames[index]
        }
    }

    func sendViewportChanges() async {
        for (key, client) in clientsByTransport {
            guard let transport = transports[key] else { continue }
            await sendEvent(
                .viewportChanged(
                    physicalSize: client.viewportFrame.size,
                    safeArea: .zero
                ),
                to: transport
            )
        }
    }

    func viewportFrames(count: Int, outputSize: Size<Int>) -> [Rect<Int>] {
        guard count > 0 else { return [] }
        let columns: Int
        let rows: Int

        switch count {
        case 1:
            columns = 1
            rows = 1
        case 2:
            columns = 2
            rows = 1
        default:
            columns = 2
            rows = Int(ceil(Double(count) / 2.0))
        }

        var result: [Rect<Int>] = []
        for index in 0 ..< count {
            let col = index % columns
            let row = index / columns
            let left = outputSize.width * col / columns
            let right = outputSize.width * (col + 1) / columns
            let top = outputSize.height * row / rows
            let bottom = outputSize.height * (row + 1) / rows
            result.append(Rect(x: left, y: top, width: right - left, height: bottom - top))
        }
        return result
    }

    func rendererOutputSize() -> Size<Int> {
        if let size = try? rendererServer.renderer.getOutputSize() {
            return Size(size.0, size.1)
        }
        if let size = window?.rendererSize {
            return Size(size.width, size.height)
        }
        return Size(800, 600)
    }

    func collectExpiredResources() {
        let now = SDL_GetTicks64()
        let expired = lingeringResources.compactMap { handle, pending in
            pending.expiresAt <= now ? handle : nil
        }
        for handle in expired {
            freeResource(handle)
        }
    }

    func freeResource(_ handle: ResHandle) {
        lingeringResources[handle] = nil
        proceduralImages[handle] = nil
        soundResources[handle] = nil
        fontResources[handle] = nil
        resourceOrigins[handle] = nil

        if let owner = resourceOwners.removeValue(forKey: handle) {
            for client in clientsByTransport.values where client.clientId == owner {
                client.ownedResources.remove(handle)
            }
        }

        rendererServer.resourceStore.unloadResource(handle)
    }

    func hotReloadPack(named name: String) {
        for (handle, origin) in resourceOrigins {
            guard case let .pack(url, kind, density) = origin, url.host == name else { continue }
            switch kind {
            case .image:
                guard let image = rendererServer.imageManager.image(url) else { continue }
                image.resourceId = handle
                rendererServer.resourceStore._idImageCache[handle] = image

            case .font:
                guard var font = fontResources[handle] else { continue }
                if let family = try? readFontFamily(url: url) {
                    font = FontResource(ownerClientId: font.ownerClientId, family: family, url: font.url, uploadedData: font.uploadedData)
                    fontResources[handle] = font
                }

            case .sound:
                let owner = resourceOwners[handle] ?? 0
                soundResources[handle] = SoundResource(ownerClientId: owner, url: url, uploadedData: nil)
                _ = density
            }
        }

        for (handle, _) in proceduralImages {
            try? rebuildProceduralImage(handle)
        }
    }

    func rebuildProceduralImage(_ handle: ResHandle) throws {
        guard let procedural = proceduralImages[handle] else { return }
        switch procedural.base {
        case let .blank(size):
            let pixelData = try PixelData(size)
            try setImage(handle: handle, pixelData: pixelData)

        case let .copy(source):
            let sourceImage = try rendererServer.resourceStore.fetchResource(source)
            let pixelData = try sourceImage.readPixelData()
            try setImage(handle: handle, pixelData: pixelData)
        }

        try draw(commands: procedural.journal, into: handle)
    }

    func setImage(handle: ResHandle, pixelData: PixelData) throws {
        if let existing = rendererServer.resourceStore._idImageCache[handle] {
            let existingSize = existing.size
            let newSize = pixelData.size()
            if existingSize.width == Int32(newSize.width), existingSize.height == Int32(newSize.height) {
                try rendererServer.imageManager.updateImage(existing, pixelData)
                return
            }
        }

        guard let atlasImage = rendererServer.imageManager.image(pixelData) else {
            throw DisplayServerError.server("unable to create image resource")
        }
        atlasImage.resourceId = handle
        rendererServer.resourceStore._idImageCache[handle] = atlasImage
    }

    func requireOwnership(handle: ResHandle, client: ClientState) throws {
        guard resourceOwners[handle] == client.clientId else {
            throw DisplayServerError.notFound("resource not found")
        }
    }

    func requireDrawableAccess(handle: ResHandle, client: ClientState) throws {
        if resourceOwners[handle] == client.clientId {
            return
        }
        if rendererServer.resourceStore._idImageCache[handle] != nil {
            return
        }
        if fontResources[handle] != nil {
            return
        }
        throw DisplayServerError.notFound("resource not found")
    }

    func handleExists(_ handle: ResHandle) -> Bool {
        handle != 0 && (
            rendererServer.resourceStore._idImageCache[handle] != nil ||
            fontResources[handle] != nil ||
            soundResources[handle] != nil ||
            resourceOwners[handle] != nil
        )
    }

    private func track(handle: ResHandle, owner client: ClientState, origin: ResourceOrigin) {
        resourceOwners[handle] = client.clientId
        resourceOrigins[handle] = origin
        lingeringResources[handle] = nil
        client.ownedResources.insert(handle)
    }

    func generateHandle() -> ResHandle {
        var value: ResHandle = 0
        repeat {
            value = Xoroshiro.shared.randomBytes()
        } while handleExists(value)
        return value
    }

    func readFontFamily(url: VDUrl) throws -> String {
        let data = try rendererServer.imageManager._dataSource.fetch(url)
        return try readFontFamily(data: data, fallbackURL: url)
    }

    func readFontFamily(data: [UInt8], fallbackURL: VDUrl) throws -> String {
        let font = try SDL2_TTFSwift.Font(data: data, ptSize: 14)
        return font.faceFamilyName() ?? fallbackURL.deletingPathExtension().lastPathComponent
    }

    func pixelDataFromImageBytes(_ data: [UInt8]) throws -> PixelData {
        var mutable = data
        let surface = try mutable.withUnsafeMutableBytes { ptr in
            try Surface(bmpDataPtr: ptr)
        }
        return PixelData(surface)
    }

    func bytes(from pixelData: PixelData) throws -> [UInt8] {
        try pixelData.withPixelData { rawData in
            Array(rawData.ptr)
        }
    }

    func screenshotBody() throws -> ResponseBody {
        let (w, h) = try rendererServer.renderer.getOutputSize()
        let target = try Texture(renderer: rendererServer.renderer, format: .argb8888, access: .target, width: w, height: h)
        let prevTarget = try rendererServer.renderer.swapTarget(target)
        defer { try? rendererServer.renderer.setTarget(prevTarget) }
        try rendererServer.renderer.setDrawColor(red: 0, green: 0, blue: 0, alpha: 255)
        try rendererServer.renderer.clear()
        rendererServer.drawingInterpolator.draw(SDL_GetTicks64())
        let format = try PixelFormat(format: .argb8888)
        let surface = try rendererServer.renderer.readPixels(format: format)
        var rgba = [UInt8](repeating: 0, count: w * h * 4)
        try surface.withPixelData { raw in
            let pitch = raw.pitch
            for row in 0..<h {
                for col in 0..<w {
                    let src = row * pitch + col * 4
                    let dst = (row * w + col) * 4
                    rgba[dst + 0] = raw.ptr[src + 2] // R
                    rgba[dst + 1] = raw.ptr[src + 1] // G
                    rgba[dst + 2] = raw.ptr[src + 0] // B
                    rgba[dst + 3] = raw.ptr[src + 3] // A
                }
            }
        }
        return .pixelData(handle: 0, size: Size(w, h), data: rgba)
    }

    func sanitizeFileName(_ name: String) -> String {
        let invalid = CharacterSet.alphanumerics.inverted
        let parts = name.components(separatedBy: invalid).filter { !$0.isEmpty }
        return parts.isEmpty ? "pack" : parts.joined(separator: "-")
    }

    func namespacedAnimationId(_ value: UInt64, clientId: ClientId) -> UInt64 {
        guard value != 0 else { return 0 }
        let masked = value & 0x00FF_FFFF_FFFF_FFFF
        return (UInt64(clientId) << 56) | masked
    }

    func scaledRect(_ rect: Rect<Int>, scale: Float) -> Rect<Int> {
        guard rect != .zero else { return rect }
        return Rect(
            x: Int((Float(rect.x) * scale).rounded()),
            y: Int((Float(rect.y) * scale).rounded()),
            width: Int((Float(rect.width) * scale).rounded()),
            height: Int((Float(rect.height) * scale).rounded())
        )
    }

    func scaledPoint(_ point: Point<Int>, scale: Float) -> Point<Int> {
        Point(
            Int((Float(point.x) * scale).rounded()),
            Int((Float(point.y) * scale).rounded())
        )
    }

    func effectiveClipRect(for rect: Rect<Int>, viewport: Rect<Int>) -> Rect<Int> {
        if rect == .zero {
            return viewport
        }
        var clipped = rect
        clipped.clip(viewport)
        return clipped
    }

    func resolvedDest(_ dest: Rect<Int>, parentId: UInt64, positions: inout [UInt64:Rect<Int>]) -> Rect<Int> {
        guard parentId != 0, let parent = positions[parentId] else {
            return dest
        }
        return Rect(x: parent.x + dest.x, y: parent.y + dest.y, width: dest.width, height: dest.height)
    }

    func colorComponents(_ color: SDLColor, alpha: Float) -> (UInt8, UInt8, UInt8, UInt8) {
        let raw = color.rawValue
        let a = UInt8((raw >> 24) & 0xFF)
        let r = UInt8((raw >> 16) & 0xFF)
        let g = UInt8((raw >> 8) & 0xFF)
        let b = UInt8(raw & 0xFF)
        return (r, g, b, UInt8(Float(a) * alpha))
    }

    func drawFill(_ cmd: DrawCmd, dest: Rect<Int>) throws {
        let (r, g, b, a) = colorComponents(cmd.color, alpha: cmd.alpha)
        try rendererServer.renderer.setDrawColor(red: r, green: g, blue: b, alpha: a)
        try rendererServer.renderer.fill(rect: dest.sdlRect())
    }

    func drawView(_ cmd: DrawCmd, borderColor: SDLColor, borderWidth: Int, dest: Rect<Int>) throws {
        let (bgR, bgG, bgB, bgA) = colorComponents(cmd.color, alpha: cmd.alpha)
        if bgA > 0 {
            try rendererServer.renderer.setDrawColor(red: bgR, green: bgG, blue: bgB, alpha: bgA)
            try rendererServer.renderer.fill(rect: dest.sdlRect())
        }
        guard borderWidth > 0 else { return }

        let bw = borderWidth
        let (r, g, b, a) = colorComponents(borderColor, alpha: 1.0)
        try rendererServer.renderer.setDrawColor(red: r, green: g, blue: b, alpha: a)
        try rendererServer.renderer.fill(rect: Rect(x: dest.x, y: dest.y, width: dest.width, height: bw).sdlRect())
        try rendererServer.renderer.fill(rect: Rect(x: dest.x, y: dest.bottom - bw, width: dest.width, height: bw).sdlRect())
        try rendererServer.renderer.fill(rect: Rect(x: dest.x, y: dest.y + bw, width: bw, height: dest.height - bw * 2).sdlRect())
        try rendererServer.renderer.fill(rect: Rect(x: dest.right - bw, y: dest.y + bw, width: bw, height: dest.height - bw * 2).sdlRect())
    }
}

private extension CompositionCmd {
    var handle: ResHandle {
        switch self {
        case let .createEditableImage(handle, _),
             let .createProceduralImage(handle, _),
             let .copyToEditable(handle, _),
             let .copyToProceduralImage(handle, _):
            return handle
        }
    }
}
