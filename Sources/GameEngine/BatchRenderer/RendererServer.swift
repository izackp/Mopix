//
//  RendererServer.swift
//
//
//  Created by Isaac Paul on 5/9/23.
//

import SDL2
import SDL2Swift
import ChunkedPool

extension BitMaskOptionSet<Renderer.RendererFlip> {
    func hasValue() -> Bool {
        return self.contains(.horizontal) || self.contains(.vertical)
    }
}

public class RendererServer {

    public init(renderer: Renderer, imageManager:ImageManager) {
        self.renderer = renderer
        self.imageManager = imageManager
        let resourceStore = ResourceStore(imageManager)
        self.resourceStore = resourceStore
        self.drawingInterpolator = DrawCmdInterpolator(renderer: renderer, resourceStore: resourceStore)
        // Wire ResourceStore into ImageManager so newly created Fonts can register glyphs
        imageManager.resourceStore = resourceStore
    }

    let imageManager:ImageManager
    let resourceStore:ResourceStore
    let renderer:Renderer
    let drawingInterpolator:DrawCmdInterpolator

    public func draw(_ imageUrl:VDUrl, rect:Rect<Int>, _ color:SDLColor = SDLColor.white, alpha:Float = 1) {
        guard let image = imageManager.image(imageUrl) else { return }
        try? renderer.draw(image, rect.sdlRect(), color)
    }

    func receiveCmdsSync(_ list: [DrawCmd]) {
        resourceStore.increaseTicks()
        drawingInterpolator.receiveCmds(list)
    }
}

// MARK: - IRendererServer + IRTTAllocator
extension RendererServer: IRendererServer, IRTTAllocator {
    public func loadResource(_ url: VDUrl) async throws -> Image {
        try await MainActor.run() {
            try resourceStore.loadResource(url)
        }
    }
    public func loadResourceAsEditable(_ url: VDUrl) async throws -> ReadOnlyImage {
        try await MainActor.run() {
            try resourceStore.loadResourceAsEditable(url)
        }
    }
    public func loadResource(_ image: PixelData) async throws -> ReadOnlyImage {
        try await MainActor.run() {
            try resourceStore.loadResource(image)
        }
    }
    public func loadResources(_ urlList: [VDUrl]) async -> [Result<Image, Error>] {
        await MainActor.run() {
            resourceStore.loadResources(urlList)
        }
    }
    public func loadResource(_ url: VDUrl, _ choosenId: UInt64) async throws -> Image {
        try await MainActor.run() {
            try resourceStore.loadResource(url, choosenId)
        }
    }
    public func loadResourceAsEditable(_ url: VDUrl, _ choosenId: UInt64) async throws -> ReadOnlyImage {
        try await MainActor.run() {
            try resourceStore.loadResourceAsEditable(url, choosenId)
        }
    }
    public func loadResource(_ image: PixelData, _ choosenId: UInt64) async throws -> ReadOnlyImage {
        try await MainActor.run() {
            try resourceStore.loadResource(image, choosenId)
        }
    }
    public func loadResources(_ urlList: [VDUrl], _ choosenId: [UInt64]) async -> [Result<Image, Error>] {
        await MainActor.run() {
            resourceStore.loadResources(urlList, choosenId)
        }
    }
    public func unloadResource(_ id: ImageResource) async {
        await MainActor.run() {
            resourceStore.unloadResource(id)
        }
    }
    public func unloadResources(_ idList: [ImageResource]) async {
        await MainActor.run() {
            resourceStore.unloadResources(idList)
        }
    }
    public func updateImage(_ image: EditedImage) async throws -> ReadOnlyImage {
        try await MainActor.run() {
            try resourceStore.updateImage(image)
        }
    }
    public func toImage(_ id: ImageFlyWeight) async throws -> Image {
        try await MainActor.run() {
            try resourceStore.toImage(id)
        }
    }
    public func toEditableImage(_ id: ImageFlyWeight) async throws -> ReadOnlyImage {
        try await MainActor.run() {
            try resourceStore.toEditableImage(id)
        }
    }

    public func receiveCmds(_ list: [DrawCmd]) async {
        await MainActor.run() {
            receiveCmdsSync(list)
        }
    }

    // MARK: - IRTTAllocator

    /// Allocates a blank atlas region and registers it with the ResourceStore.
    /// Called by UICommandContext.createAndDrawToTexture.
    public func allocate(size: Size<DValue>) throws -> AtlasImage {
        let subTexture = try imageManager.atlas.saveBlankImage(size)
        let image = AtlasImage(texture: subTexture, atlas: imageManager.atlas)
        let id = resourceStore.registerAtlasImage(image)
        image.resourceId = id
        return image
    }

    //TODO: Use texture atlas
    /*
    func textureFor(_ id:UInt64, _ backingImage:EditableImage) throws -> Texture {
        if let existing = cache[id] {
            let texture = existing.texture
            if (existing.editIteration == backingImage.editIteration) {
                return texture
            }
            let size = backingImage.size()
            let attr = try texture.attributes()
            if (attr.width == size.width && attr.height == size.height) {
                try backingImage.withPixelData { pixelData in
                    try texture.update(pixels: pixelData.ptr, pitch: pixelData.pitch)
                }

                cache[id]?.editIteration = backingImage.editIteration
                return texture
            }
        }
        let newTexture = try Texture(renderer: renderer, surface: backingImage.getSurface())
        cache[id] = SurfaceBackedTexture(texture: newTexture, editIteration: backingImage.editIteration)
        return newTexture
    }*/
    /*
    public func draw(_ image:EditableImage, rect:Rect<Int>) {
        let objId = ObjectIdentifier(image)

        do {
            let texture = try textureFor(objId, image)
            try renderer.copy(texture, destination: rect.sdlRect())
        } catch {

        }
    }*/
}
