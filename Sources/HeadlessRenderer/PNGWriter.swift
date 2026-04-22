import Foundation
import GameEngine

// Writes raw RGBA (row-major) pixel data as an uncompressed PNG.
// Uses zlib DEFLATE store blocks (compression level 0) — no new dependencies.
func writePNG(rgba: [UInt8], size: Size<Int>, to url: URL) throws {
    let w = size.width
    let h = size.height
    var png = Data()

    // PNG signature
    png.append(contentsOf: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

    // IHDR: width(4) height(4) bitDepth(1) colorType(1) compression(1) filter(1) interlace(1)
    var ihdr = Data()
    ihdr.appendBE32(UInt32(w))
    ihdr.appendBE32(UInt32(h))
    ihdr.append(contentsOf: [8, 6, 0, 0, 0]) // 8-bit RGBA
    png.appendPNGChunk("IHDR", data: ihdr)

    // Raw image data: filter byte 0 (None) + RGBA row
    var raw = Data()
    raw.reserveCapacity((1 + w * 4) * h)
    for row in 0..<h {
        raw.append(0)
        let base = row * w * 4
        raw.append(contentsOf: rgba[base ..< base + w * 4])
    }

    png.appendPNGChunk("IDAT", data: zlibStore(raw))
    png.appendPNGChunk("IEND", data: Data())

    try png.write(to: url, options: [.atomic])
}

// Produces a valid zlib stream using only non-compressed (BTYPE=00) deflate store blocks.
private func zlibStore(_ input: Data) -> Data {
    var out = Data()
    out.append(contentsOf: [0x78, 0x01]) // zlib header (CM=8, CINFO=7, FCHECK=1)

    let blockMax = 65535
    var offset = input.startIndex
    while offset < input.endIndex {
        let end = input.index(offset, offsetBy: blockMax, limitedBy: input.endIndex) ?? input.endIndex
        let isFinal: UInt8 = end == input.endIndex ? 1 : 0
        let len = UInt16(input.distance(from: offset, to: end))
        out.append(isFinal)       // BFINAL | (BTYPE=00 << 1)
        out.appendLE16(len)       // LEN
        out.appendLE16(~len)      // NLEN (one's complement)
        out.append(contentsOf: input[offset..<end])
        offset = end
    }

    // Adler-32 checksum (big-endian)
    var s1: UInt32 = 1, s2: UInt32 = 0
    for byte in input {
        s1 = (s1 + UInt32(byte)) % 65521
        s2 = (s2 + s1) % 65521
    }
    out.appendBE32((s2 << 16) | s1)
    return out
}

// MARK: - Data helpers

private extension Data {
    mutating func appendBE32(_ v: UInt32) {
        append(UInt8((v >> 24) & 0xFF))
        append(UInt8((v >> 16) & 0xFF))
        append(UInt8((v >> 8) & 0xFF))
        append(UInt8(v & 0xFF))
    }

    mutating func appendLE16(_ v: UInt16) {
        append(UInt8(v & 0xFF))
        append(UInt8((v >> 8) & 0xFF))
    }

    mutating func appendPNGChunk(_ type: String, data: Data) {
        appendBE32(UInt32(data.count))
        let typeBytes = Array(type.utf8)
        append(contentsOf: typeBytes)
        append(data)
        var crc: UInt32 = 0xFFFFFFFF
        for b in typeBytes { crc = crcTable[Int((crc ^ UInt32(b)) & 0xFF)] ^ (crc >> 8) }
        for b in data      { crc = crcTable[Int((crc ^ UInt32(b)) & 0xFF)] ^ (crc >> 8) }
        appendBE32(crc ^ 0xFFFFFFFF)
    }
}

private let crcTable: [UInt32] = {
    (0..<256).map { n -> UInt32 in
        var c = UInt32(n)
        for _ in 0..<8 { c = c & 1 != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1 }
        return c
    }
}()
