//
//  Resources.swift
//  TestGame
//
//  Created by Isaac Paul on 4/26/22.
//

import Foundation

public typealias VDUrl = URL

public struct VDItem  {
    let url:URL
    let isFile:Bool
    let isDir:Bool
}

extension Array where Element == MountedDir {
    func withName(_ name: String) -> MountedDir? {
        for eachDir in self {
            if (eachDir.meta.name == name) {
                return eachDir
            }
        }
        return nil
    }
    func expectName(_ name: String) throws -> MountedDir {
        if let dir = self.first(where: {$0.meta.name == name}) {
            return dir
        }
        throw GenericError("Package with name \(name) not found")
    }
    
    func contains(_ url:VDUrl) -> MountedDir? {
        if (url.scheme != "vd") { return nil }
        let path = url.path
        if let host = url.host {
            return withName(host)
        }
        for eachMD in self {
            if let _ = eachMD.itemAt(path) {
                return eachMD
            }
        }
        return nil
    }
}

//Should we return file urls?\
//We kinda have to return VD Urls considering not all urls will be File urls
//It's possible we can use regular urls however it could be confusing as those paths may not actually exist

//We could return relative paths but isn't that just a VDUrl?
//maybe we use a new data structure..
protocol IFileSystem {
    func allItems(_ relPath:String, _ recursive:Bool) -> AnyIterator<VDItem>
    func searchByName(_ fileName: String) -> VDItem?
    func itemAt(_ path:String) -> VDItem?
}

extension AnyIterator<VDItem> {
    /*
    func filterFiles() -> LazyFilterSequence<AnyIterator<URL>> {
        let result = self.lazy.filter {
            do {
                let fileAttributes = try $0.resourceValues(forKeys:[.isRegularFileKey])
                return fileAttributes.isRegularFile!
            } catch {
                print(error, $0)
                return false
            }
        }
        return result
    }*/
    func filterFiles() -> LazyFilterSequence<AnyIterator<VDItem>> {
        let result = self.lazy.filter { $0.isFile }
        return result
    }
}

extension IFileSystem {
    func allItemsWithExt(_ ext:String) -> [VDItem] {
        let result = self.allItems("", true).filterFiles().filter {
            let filename: NSString = $0.url.path as NSString
            return (filename.pathExtension == ext)
        }
        return Array(result)
    }
}

public class VirtualDrive : IFileSystem {
    func allItems(_ relPath:String = "", _ recursive:Bool) -> AnyIterator<VDItem> {
        var lazySeq = packages.lazy.makeIterator()
        var lastPkg:AnyIterator<VDItem>? = lazySeq.next()?.allItems(relPath, recursive)
        let it = AnyIterator {
            if let pkg = lastPkg {
                if let nextItem = pkg.next()  {
                    return nextItem
                }
            }
            lastPkg = lazySeq.next()?.allItems(relPath, recursive)
            return lastPkg?.next()
        }
        return it
    }
    
    
    public static let shared = VirtualDrive()
    
    public init(_ listMountedDirectories: [MountedDir] = []) {
        self.packages = listMountedDirectories
    }
    
    var packages: [MountedDir] //TODO: Should be prioritized
            
    func mountPath(path:URL, mountDir:Substring = "/") throws {
        if (path.isFileURL == false) {
            throw GenericError("Url is not a file path \(path.absoluteString)")
        }
      
        if (packages.withName(path.absoluteString) != nil) {
            throw GenericError("Path is already mounted.")
        }
        let isDirectory = try path.isDirectory()
        if (isDirectory) {
            let instance = try MountedDir.newMountedDir(path: path, isDirectory: true)
            packages.append(instance)
            return
        } else {
            throw GenericError("Mounting files not supported yet.")
        }
    }

    //MARK: IFileSystem
    func searchByName(_ name:String) -> VDItem? {
        for eachMD in packages {
            if let result = eachMD.searchByName(name) {
                return result
            }
        }
        return nil
    }
    
    //Converts vd:// to a file:// url if possible
    func resolveToDirectUrl(_ item:VDItem) throws -> URL? {
        let url = item.url
        if (url.scheme != "vd") { return nil } //TODO: We should be able to assume this is the correct url
        let path = url.path
        if let host = url.host {
            let pkg = try packages.expectName(host)
            return pkg.resolveToDirectUrl(path)
        }
        return try resolveToDirectUrl(item)
    }
    
    func itemAt(_ path: String) -> VDItem? {
        for eachMD in packages {
            if let result = eachMD.itemAt(path) {
                return result
            }
        }
        return nil
    }
    
    func itemAt(_ url:URL) -> VDItem? {
        for eachMD in packages {
            if let result = eachMD.itemAt(url) {
                return result
            }
        }
        return nil
    }
    
    //File ops
    //Null if not found
    func readFile(_ url:VDUrl) throws -> Data? {
        let path = url.path
        if let host = url.host {
            let pkg = try packages.expectName(host)
            return try pkg.readFile(path)
        }
        return readFile(path)
    }
    
    func readFile(_ path: String) -> Data? {
        for eachMD in packages {
            if let result = try? eachMD.readFile(path) {
                return result
            }
        }
        return nil
    }
    
    func writeFile(_ data:Data, _ url:VDUrl) throws {
        let path = url.path
        if let host = url.host {
            let pkg = try packages.expectName(host)
            return try pkg.writeFile(data, path)
        }
        throw GenericError("No package specified.")
    }
    
    func removeWatcher(_ listener:PackageChangeListener) {
        for eachMD in packages {
            eachMD.stopWatching(listener)
        }
    }
    
}
