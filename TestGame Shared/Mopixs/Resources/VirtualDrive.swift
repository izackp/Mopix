//
//  Resources.swift
//  TestGame
//
//  Created by Isaac Paul on 4/26/22.
//

import Foundation

extension URL {
    func isDirectory() throws -> Bool {
        let res = try resourceValues(forKeys: [.isDirectoryKey])
        return res.isDirectory == true
    }
}

public typealias VDUrl = URL

public class VirtualDrive {
    public init(_ listMountedDirectories: Arr<MountedDir> = Arr<MountedDir>()) {
        self.listMountedDirectories = listMountedDirectories
    }
    
    var listMountedDirectories: Arr<MountedDir> //TODO: Should be prioritized
    func findMountedDir(_ name: String) -> MountedDir? {
        for eachDir in self.listMountedDirectories {
            if (eachDir.meta.name == name) {
                return eachDir
            }
        }
        return nil
    }
    
    func mountedDir(_ mountName:String) throws -> MountedDir {
        if let dir = listMountedDirectories.first(where: {$0.meta.name == mountName}) {
            return dir
        }
        throw GenericError("Mounted directory with name \(mountName) not found")
    }
            
    func mountPath(path:URL, mountDir:Substring = "/") throws {
        if (path.isFileURL == false) {
            throw GenericError("Url is not a file path \(path.absoluteString)")
        }
      
        if (findMountedDir(path.absoluteString) != nil) {
            throw GenericError("Path is already mounted.")
        }
        let isDirectory = try path.isDirectory()
        if (isDirectory) {
            let instance = try MountedDir.newMountedDir(path: path, isDirectory: true)
            self.listMountedDirectories.append(instance)
            return
        } else {
            throw GenericError("Mounting files not supported yet.")
        }
    }

    func filesInDirectory(_ directory: URL) throws -> [URL] {
        let path = directory.path
        if let host = directory.host {
            return try itemsInDirectory(host, path)
        }
        return itemsInDirectory(path)
    }
    
    func itemsInDirectory(_ mountedDir:MountedDir, _ path: String) throws -> [VDUrl] {
        guard let dir = listMountedDirectories.first(where: {$0 === mountedDir}) else { throw GenericError("Mounted Dir does not belong to this virtual drive")}
        return dir.itemsInDirectory(path)
    }
    
    func itemsInDirectory(_ mountName:String, _ path: String) throws -> [VDUrl] {
        let dir = try mountedDir(mountName)
        return dir.itemsInDirectory(path)
    }
    
    func itemsInDirectory(_ path: String) -> [VDUrl] {
        var items:[URL] = []
        for eachMD in listMountedDirectories {
            items.append(contentsOf: eachMD.itemsInDirectory(path))
        }
        return items
    }
    
    func urlForFileName(_ name:String) -> VDUrl? {
        for eachMD in listMountedDirectories {
            if let result = eachMD.urlForName(name) {
                return result
            }
        }
        return nil
    }
    
    func urlForPath(_ path:String) -> VDUrl? {
        for eachMD in listMountedDirectories {
            if let result = eachMD.urlForPath(path) {
                return result
            }
        }
        return nil
    }
    
    func findByExt(_ ext:String) -> [VDUrl] {
        var results:[URL] = []
        for eachMD in listMountedDirectories {
            let subResults = eachMD.itemsMatching({
                let filename: NSString = $0.path as NSString
                return filename.pathExtension == ext
            })
            results.append(contentsOf: subResults)
        }
        return results
    }
    
    //Converts vd:// to a file:// url if possible
    func resolveToDirectUrl(_ url:VDUrl) throws -> URL? {
        if (url.scheme != "vd") { return nil }
        let path = url.path
        if let host = url.host {
            return try resolveToDirectUrl(host, path)
        }
        return resolveToDirectUrl(path)
    }
    
    func resolveToDirectUrl(_ path: String) -> URL? {
        let fm = FileManager()
        for eachMD in listMountedDirectories {
            if let result = eachMD.resolveToDirectUrl(path) {
                if (fm.fileExists(atPath: result.path)) {
                    return result
                }
            }
        }
        return nil
    }
    
    func resolveToDirectUrl(_ mountName:String, _ filePath:String) throws -> URL? {
        let dir = try mountedDir(mountName)
        return dir.resolveToDirectUrl(filePath)
    }
    
    func resolveToVDUrl(_ url:URL) -> VDUrl? {
        if url.scheme == "vd" { return url }
        return resolveToVDUrl(url.path)
    }
    
    func resolveToVDUrl(_ path: String) -> VDUrl? {
        for eachMD in listMountedDirectories {
            if let result = eachMD.resolveToVDUrl(path) {
                return result
            }
        }
        return nil
    }
    
    //Null if not found
    func readFile(_ url:VDUrl) throws -> Data? {
        let path = url.path
        if let host = url.host {
            return try readFile(host, path)
        }
        return readFile(path)
    }
    
    func readFile(_ path: String) -> Data? {
        for eachMD in listMountedDirectories {
            if let result = try? eachMD.readFile(path) {
                return result
            }
        }
        return nil
    }
    
    func readFile(_ mountName:String, _ filePath:String) throws -> Data? {
        guard let dir = listMountedDirectories.first(where: {$0.meta.name == mountName}) else { throw GenericError("Mounted directory with name \(mountName) not found")}
        return try dir.readFile(filePath)
    }
    
    
    func writeFile(_ url:URL) {
        
    }
    
    public static let shared = VirtualDrive()
}
