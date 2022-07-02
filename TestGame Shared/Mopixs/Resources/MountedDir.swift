//
//  MountedDir.swift
//  TestGame
//
//  Created by Isaac Paul on 4/26/22.
//

import Foundation

let VersionChars = CharacterSet(charactersIn: ".").union(CharacterSet.decimalDigits)

extension URL {
    func vdPath(from base: URL, packageInfo:PackageMeta? = nil) throws -> URL {

        // Remove/replace "." and "..", make paths absolute:
        let destComponents = self.standardized.pathComponents
        let baseComponents = base.standardized.pathComponents
        
        if (destComponents.count < baseComponents.count) {
            throw GenericError("Current path is not relative to provided path: \(self) -> \(base)")
        }

        for i in 0..<baseComponents.count {
            if (destComponents[i] != baseComponents[i]) {
                throw GenericError("Current path is not relative to provided path: \(self) -> \(base)")
            }
        }

        // Build relative path:
        let path = destComponents[baseComponents.count...].joined(separator: "/")
        let urlStr:String
        if let packageInfo = packageInfo {
            urlStr = "vd://\(packageInfo.toString())/\(path)"
        } else {
            urlStr = "vd:/\(path)" //TODO: Should never happen?
        }
        guard let newUrl = URL(string: urlStr) else {
            throw GenericError("Could not build url from path: \(path)")
        }
        return newUrl
    }
}

public struct PackageMeta {
    let name:String
    let version:Version
    
    static func parseMetaFromName(_ name:String) throws -> PackageMeta {
        let subStr = name.substring(from: 0)
        var scanner = StringScanner(span: subStr, pos: name.count - 1, dir: -1)
        let revision = Int(try scanner.readInt32())
        try scanner.expect(c: ".")
        let minor = Int(try scanner.readInt32())
        try scanner.expect(c: ".")
        let major = Int(try scanner.readInt32())
        try scanner.expect(c: "_")
        let finalName = String(name[0...scanner.pos])
        let version = try Version(major, minor, revision)
        return PackageMeta(name: finalName, version: version)
    }
    
    init(name:String, version:Version) {
        self.name = name
        self.version = version
    }
    
    func toString() -> String {
        return "name_\(version.toString())"
    }
}

public class MountedDir {
    init(meta: PackageMeta, path: URL, virtualPath: String, isReadOnly: Bool, isDirectory:Bool, isIndexed:Bool = true) {
        self.meta = meta
        self.path = path
        self.virtualPath = virtualPath
        self.isReadOnly = isReadOnly
        self.isIndexed = isIndexed
        self.isDirectory = isDirectory
    }
    
    let meta:PackageMeta
    let path:URL
    let virtualPath:String
    let isReadOnly:Bool
    let isIndexed:Bool // Allows being searched for resources
    let isDirectory:Bool
    //var files:[URL] = []
    
    // Note: Foresee problems with /my/path/../
    static func newMountedDir(path:URL, isDirectory:Bool, mountDir:String = String(OS.defaultPathSeparator)) throws -> MountedDir {
        // TODO: Check if file is writable/readable
        let lastPart = path.lastPathComponent
        var fileORDirPath:URL
        if (isDirectory) {
            fileORDirPath = path
        } else {
            let parent = path.deletingLastPathComponent()
            fileORDirPath = parent
        }

        if lastPart.count == 0 {
            throw GenericError("last component in path is empty: \(path)")
        }
        let meta = (try? PackageMeta.parseMetaFromName(lastPart)) ?? PackageMeta(name: lastPart, version: Version.zero)
        return MountedDir(meta:meta, path:fileORDirPath, virtualPath:mountDir, isReadOnly:false, isDirectory: isDirectory)
    }
    
    func filesInDirectory(_ dir:String) -> [URL] {
        return itemsInDirectory(dir, filter: {
            guard let isDir = try? $0.isDirectory() else {
                return false
            }
            return isDir == false
        })
    }
    
    func foldersInDirectory(_ dir:String) -> [URL] {
        return itemsInDirectory(dir, filter: {
            guard let isDir = try? $0.isDirectory() else {
                return false
            }
            return isDir
        })
    }
    
    func itemsInDirectory(_ dir:String, filter:((URL)->Bool)? = nil) -> [URL] {
        let fm = FileManager()
        do {
            let dirUrl = path.appendingPathComponent(dir)
            let directoryContents = try fm.contentsOfDirectory(at: dirUrl, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsSubdirectoryDescendants])
            let filtered:[URL]
            if let filter = filter {
                filtered = directoryContents.filter(filter)
            } else {
                filtered = directoryContents
            }
            let mapped = try filtered.map({try $0.vdPath(from: path)})
            return mapped
        }
        catch {
            print(error.localizedDescription)
            return []
        }
    }
    
    //TODO: Make iterator...
    //TODO: Somehow convey errors
    func itemsMatching(_ filter:((URL)->Bool)) -> [URL] {
        let fm = FileManager()
        let dirUrl = path
        var filtered:[URL] = []
        if let enumerator = fm.enumerator(at: dirUrl, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! && filter(fileURL) {
                        let vdPath = try fileURL.vdPath(from: path)
                        filtered.append(vdPath)
                    }
                } catch { print(error, fileURL) }
            }
        }
        //let mapped = try filtered.map({try $0.vdPath(from: path)})
        return filtered
    }
    
    func urlForPath(_ filePath:String) -> URL? {
        let fileUrl = path.appendingPathComponent(filePath)
        let fm = FileManager()
        if (fm.fileExists(atPath: fileUrl.path)) {
            return try? fileUrl.vdPath(from: path)
        }
        return nil
    }
    
    func urlForName(_ fileName:String) -> URL? {
        let result = itemsMatching({ $0.lastPathComponent == fileName })
        return result.first
    }
    
    func resolveToDirectUrl(_ filePath:String) -> URL? {
        if (isDirectory == false) { return nil }
        let fileUrl = path.appendingPathComponent(filePath)
        return fileUrl
    }
    
    func resolveToVDUrl(_ filePath:String) -> VDUrl? {
        if (isDirectory == false) { return nil }
        let fileUrl = path.appendingPathComponent(filePath)
        let fm = FileManager()
        if (fm.fileExists(atPath: fileUrl.path)) {
            return try? fileUrl.vdPath(from: path)
        }
        return nil
    }
    
    func readFile(_ filePath:String) throws -> Data? {
        let fileUrl = path.appendingPathComponent(filePath)
        return try Data(contentsOf: fileUrl)
    }
    
    func writeFile(_ data:Data, _ filePath:String) {
        
    }
}

typealias DirectoryPath = Substring
typealias FilePath = Substring

/*
when isMainModule:
  without meta =? parseMetaFromName("MyPackage_1_23_0"), error:
    echo error.msg
  echo meta.version
  echo meta.name
*/
