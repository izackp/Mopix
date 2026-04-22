//
//  EditableImage.swift
//
//
//  A mutable surface-backed image used for procedural generation (particles,
//  etc.) and registered with a RendererClient via `loadResource`/`updateImage`.
//

import SDL2
import SDL2Swift

public class EditableImage {
    public internal(set) var id: UInt64
    let _data: PixelData
    var _dirty: Bool = false

    public init(_ data: PixelData, id: UInt64 = 0) {
        self.id = id
        self._data = data
    }

    public init(_ size: Size<Int>, id: UInt64 = 0) throws {
        self.id = id
        self._data = try PixelData(size)
    }

    public func size() -> Size<Int> {
        return _data.size()
    }

    public func bounds() -> Rect<Int> {
        return Rect(origin: .zero, size: size())
    }

    public func fill(rect: SDL_Rect? = nil, color: Color) throws {
        _dirty = true
        try _data.fill(rect: rect, color: color)
    }

    public func drawPoint(_ x: Int32, _ y: Int32, _ color: UInt32) throws {
        _dirty = true
        try _data.drawPoint(x, y, color)
    }

    public func resize(_ size: Size<Int>) throws {
        _dirty = true
        try _data.resize(size)
    }

    func withPixelData<Result>(_ body:(_ pixelData: RawPixelData) throws -> (Result)) throws -> Result {
        return try _data.withPixelData(body)
    }

    func editPixelData<Result>(_ body:(_ pixelData: MutableRawPixelData) throws -> (Result)) throws -> Result {
        _dirty = true
        return try _data.withMutablePixelData(body)
    }

    internal func getPixelData() -> PixelData {
        return _data
    }

    internal func getSurface() -> Surface {
        return _data._surface
    }
}
