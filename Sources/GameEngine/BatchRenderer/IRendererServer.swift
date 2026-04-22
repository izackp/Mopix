//
//  IRendererServer.swift
//
//
//  Created by Isaac Paul on 3/3/26.
//

// The surface RendererClient needs from the server side.
// All methods are async so the seam is compatible with both in-process
// and network (remote) implementations.
public protocol IRendererServer: AnyObject {

    // MARK: - Load
    func loadResource(_ url: VDUrl) async throws -> Image
    func loadResourceAsEditable(_ url: VDUrl) async throws -> ReadOnlyImage
    func loadResource(_ image: PixelData) async throws -> ReadOnlyImage
    func loadResources(_ urlList: [VDUrl]) async -> [Result<Image, Error>]

    func loadResource(_ url: VDUrl, _ choosenId: UInt64) async throws -> Image
    func loadResourceAsEditable(_ url: VDUrl, _ choosenId: UInt64) async throws -> ReadOnlyImage
    func loadResource(_ image: PixelData, _ choosenId: UInt64) async throws -> ReadOnlyImage
    func loadResources(_ urlList: [VDUrl], _ choosenId: [UInt64]) async -> [Result<Image, Error>]

    // MARK: - Unload
    func unloadResource(_ id: ImageResource) async
    func unloadResources(_ idList: [ImageResource]) async

    // MARK: - Convert / Update
    func updateImage(_ image: EditedImage) async throws -> ReadOnlyImage
    func updateImage(_ id: UInt64, _ data: PixelData) async throws
    func toImage(_ id: ImageFlyWeight) async throws -> Image
    func toEditableImage(_ id: ImageFlyWeight) async throws -> ReadOnlyImage

    // MARK: - Draw commands
    func receiveCmds(_ list: [DrawCmd]) async
}
