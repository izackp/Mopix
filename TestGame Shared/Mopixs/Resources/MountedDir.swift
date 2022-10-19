//
//  MountedDir.swift
//  TestGame
//
//  Created by Isaac Paul on 4/26/22.
//

import Foundation

#if os(macOS)
import EonilFSEvents
#endif

public protocol PackageChangeListener : AnyObject {
    func fileChanges(_ files:[VDItem])
}

public class MountedDir : IFileSystem {
    
    let meta:PackageMeta
    let path:URL
    let virtualPath:String
    let isReadOnly:Bool
    let isIndexed:Bool // Allows being searched for resources
    let isDirectory:Bool
    
    private var _fileWatchers = WeakArray<PackageChangeListener>([])
    var fileWatchers:WeakArray<PackageChangeListener> { get { return _fileWatchers } }
    
    #if os(macOS)
    private var _eventStream:EonilFSEventStream? = nil
    #endif
    
    init(meta: PackageMeta, path: URL, virtualPath: String, isReadOnly: Bool, isDirectory:Bool, isIndexed:Bool = true) {
        self.meta = meta
        self.path = path
        self.virtualPath = virtualPath
        self.isReadOnly = isReadOnly
        self.isIndexed = isIndexed
        self.isDirectory = isDirectory
    }
    
    //NOTE: Foresee problems with /my/path/../
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
    
    
    func allItems(_ relPath:String = "", _ recursive:Bool) -> AnyIterator<VDItem> {
        let fm = FileManager()
        let dirUrl = path.appendingPathComponent(relPath)
        let options:FileManager.DirectoryEnumerationOptions
        if (recursive) {
            options = [.skipsHiddenFiles, .skipsPackageDescendants]
        } else {
            options = [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        }
        
        let pathCopy = path
        
        if let enumerator = fm.enumerator(at: dirUrl, includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey], options: options) {
            let otherResult = AnyIterator {
                let p1 = enumerator.nextObject() as? URL
                if let p1 = p1 {
                    do {
                        let fileAttributes = try p1.resourceValues(forKeys:[.isRegularFileKey, .isDirectoryKey])
                        let vdUrl = try p1.vdPath(from: pathCopy)
                        return VDItem(url: vdUrl, isFile: fileAttributes.isRegularFile!, isDir: fileAttributes.isDirectory!)
                    } catch {
                        print(error, p1)
                    }
                }
                return nil //TODO: In what cases does this fail? if it does it prevents the enumeration of all the files
            }
            return otherResult
        }
        let empty = AnyIterator {
            let url:VDItem? = nil
            return url
        }
        return empty
    }
    
    func searchByName(_ fileName:String) -> VDItem? {
        let result = allItems("", true).lazy.first(where: {
            $0.url.lastPathComponent == fileName
        })
        return result
    }
    
    func resolveToDirectUrl(_ filePath:String) -> URL? {
        if (isDirectory == false) { return nil }
        let fileUrl = path.appendingPathComponent(filePath)
        return fileUrl
    }
    
    func itemAt(_ relPath: String) -> VDItem? {
        if (isDirectory == false) { return nil }
        let fileUrl = path.appendingPathComponent(relPath)
        let fm = FileManager()
        var isDir : ObjCBool = false
        if
          (fm.fileExists(atPath: fileUrl.path, isDirectory: &isDir)),
          let vdUrl = try? fileUrl.vdPath(from: path) { //TODO: Should throw
            
            let isDirBl = isDir.boolValue
            return VDItem(url: vdUrl, isFile: !isDirBl, isDir: isDirBl) //TODO: odd behavior; we know if its not a directory but we don't know if its a file; could alias or something else
        }
        return nil
    }
    
    func itemAt(_ fileUrl:URL) -> VDItem? {
        if (isDirectory == false) { return nil }
        let fm = FileManager()
        var isDir : ObjCBool = false
        if
          (fm.fileExists(atPath: fileUrl.path, isDirectory: &isDir)),
          let vdUrl = try? fileUrl.vdPath(from: path) {
            let isDirBl = isDir.boolValue
            return VDItem(url: vdUrl, isFile: !isDirBl, isDir: isDirBl)
        }
        return nil
    }
    
    //
    func readFile(_ relPath:String) throws -> Data {
        let fileUrl = path.appendingPathComponent(relPath)
        return try Data(contentsOf: fileUrl)
    }
    
    func writeFile(_ data:Data, _ relPath:String) throws {
        guard let url = resolveToDirectUrl(relPath) else { throw GenericError("Cannot resolve \(relPath) to url")}
        try data.write(to: url, options: [.atomic])
        guard let url = itemAt(url.path) else { return }
        for eachListener in _fileWatchers {
            eachListener?.fileChanges([url])
        }
    }
    
    func readFile(_ item:VDItem) throws -> Data {
        let url = item.url
        let itemPath = url.path
        if let host = url.host {
            if (host != meta.name) {
                throw GenericError("Current package \(meta.name) doesnt match expected package: \(host)")
            }
        }
        
        let fileUrl = path.appendingPathComponent(itemPath)
        return try Data(contentsOf: fileUrl)
    }
    
    func writeFile(_ data:Data, _ item:VDItem) throws {
        let url = item.url
        let relPath = url.path
        if let host = url.host {
            if (host != meta.name) {
                throw GenericError("Current package \(meta.name) doesnt match expected package: \(host)")
            }
        }
        
        try writeFile(data, relPath)
    }
    
    //TODO: Not thread safe
    #if os(macOS)
    func startWatching(_ listener:PackageChangeListener) throws {
        if _fileWatchers.contains(where: { $0 === listener }) {
            return
        }
        _fileWatchers.append(listener)
        if (_eventStream == nil) {
            let finalPath = path.path
            print("Watching: \(finalPath)")
            let s = try EonilFSEventStream(pathsToWatch: [finalPath], sinceWhen: .now, latency: 0, flags: [EonilFSEventsCreateFlags.fileEvents], handler: { [weak self] in
                self?.eventHandler($0)
            })
            s.setDispatchQueue(DispatchQueue.main)
            try s.start()
            _eventStream = s
        }
    }
    
    func stopWatching(_ listener:PackageChangeListener) {
        _fileWatchers.clean()
        if let index = _fileWatchers.firstIndex(where: { $0 === listener }) {
            _fileWatchers.remove(at: index)
        }
        if let stream = _eventStream, (_fileWatchers.isEmpty) {
            stream.stop()
            stream.invalidate()
            _eventStream = nil
        }
    }
    
    private func eventHandler(_ event:EonilFSEventsEvent) {
        let idStr:String
        if let id = event.ID?.rawValue {
            idStr = "\(id)"
        } else {
            idStr = "nil"
        }
        print("FS Event Received:\n\tpath: \(event.path)\n\tID: \(idStr)\n\tflags: \(event.flag?.debugDescription ?? "nil")")
        if let flags = event.flag {
            if (flags.contains(.itemModified)) {
                guard
                    let fileUrl = URL(string: event.path),
                    let vdItem = itemAt(fileUrl) else { return }
                for eachListener in _fileWatchers {
                    eachListener?.fileChanges([vdItem])
                }
            }
        }
    }
    #endif
    
#if os(iOS)
    func startWatching(_ listener:PackageChangeListener) throws {
        if _fileWatchers.contains(where: { $0 === listener }) {
            return
        }
        _fileWatchers.append(listener)
    }
    
    func stopWatching(_ listener:PackageChangeListener) {
        _fileWatchers.clean()
        if let index = _fileWatchers.firstIndex(where: { $0 === listener }) {
            _fileWatchers.remove(at: index)
        }
    }
    #endif
}

typealias DirectoryPath = Substring
typealias FilePath = Substring
