import Foundation
import libzstd

// Simple archive format: magic + version + file entries, ZSTD-compressed.
// Each entry: UInt32 path length, UTF-8 path, UInt64 data length, data bytes.
enum PackArchive {
    private static let magic: [UInt8] = [0x4D, 0x4F, 0x50, 0x58] // "MOPX"
    private static let version: UInt8 = 1

    static func encode(directory: URL) throws -> [UInt8] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            throw PackArchiveError.cannotEnumerate
        }
        var body = Data()
        var fileCount: UInt32 = 0
        for case let fileURL as URL in enumerator {
            let isRegular = try fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile ?? false
            guard isRegular else { continue }
            let rel = fileURL.path.dropFirst(directory.path.count + 1)
            guard let pathBytes = rel.data(using: .utf8) else { continue }
            let fileData = try Data(contentsOf: fileURL)
            var pathLen = UInt32(pathBytes.count).littleEndian
            var dataLen = UInt64(fileData.count).littleEndian
            body.append(contentsOf: withUnsafeBytes(of: &pathLen) { Array($0) })
            body.append(pathBytes)
            body.append(contentsOf: withUnsafeBytes(of: &dataLen) { Array($0) })
            body.append(fileData)
            fileCount += 1
        }
        var header = Data(magic)
        header.append(version)
        var count = fileCount.littleEndian
        header.append(contentsOf: withUnsafeBytes(of: &count) { Array($0) })
        let raw = header + body
        return try compress(raw)
    }

    static func decode(data: [UInt8], into destination: URL) throws {
        let raw = try decompress(data)
        var offset = raw.startIndex
        guard raw.count >= 5 else { throw PackArchiveError.invalidFormat("too short") }
        let magicBytes = Array(raw[offset ..< offset + 4])
        guard magicBytes == magic else { throw PackArchiveError.invalidFormat("bad magic") }
        offset += 4
        guard raw[offset] == version else { throw PackArchiveError.invalidFormat("unsupported version") }
        offset += 1
        let fileCount = UInt32(littleEndian: raw[offset ..< offset + 4].withUnsafeBytes { $0.load(as: UInt32.self) })
        offset += 4
        let fm = FileManager.default
        for _ in 0 ..< fileCount {
            let pathLen = Int(UInt32(littleEndian: raw[offset ..< offset + 4].withUnsafeBytes { $0.load(as: UInt32.self) }))
            offset += 4
            guard let path = String(bytes: raw[offset ..< offset + pathLen], encoding: .utf8) else {
                throw PackArchiveError.invalidFormat("invalid path encoding")
            }
            offset += pathLen
            let dataLen = Int(UInt64(littleEndian: raw[offset ..< offset + 8].withUnsafeBytes { $0.load(as: UInt64.self) }))
            offset += 8
            let fileData = raw[offset ..< offset + dataLen]
            offset += dataLen
            let dest = destination.appendingPathComponent(path)
            try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(fileData).write(to: dest, options: [.atomic])
        }
    }

    private static func compress(_ data: Data) throws -> [UInt8] {
        let bound = ZSTD_compressBound(data.count)
        var dst = [UInt8](repeating: 0, count: bound)
        let result = data.withUnsafeBytes { src in
            ZSTD_compress(&dst, bound, src.baseAddress!, data.count, 3)
        }
        guard ZSTD_isError(result) == 0 else {
            throw PackArchiveError.compressionFailed(String(cString: ZSTD_getErrorName(result)))
        }
        return Array(dst.prefix(result))
    }

    private static func decompress(_ data: [UInt8]) throws -> Data {
        let frameSize = ZSTD_getFrameContentSize(data, data.count)
        guard frameSize != ZSTD_CONTENTSIZE_ERROR, frameSize != ZSTD_CONTENTSIZE_UNKNOWN else {
            throw PackArchiveError.decompressionFailed("cannot determine decompressed size")
        }
        var dst = [UInt8](repeating: 0, count: Int(frameSize))
        let result = ZSTD_decompress(&dst, Int(frameSize), data, data.count)
        guard ZSTD_isError(result) == 0 else {
            throw PackArchiveError.decompressionFailed(String(cString: ZSTD_getErrorName(result)))
        }
        return Data(dst.prefix(result))
    }
}

enum PackArchiveError: Error {
    case cannotEnumerate
    case invalidFormat(String)
    case compressionFailed(String)
    case decompressionFailed(String)
}
