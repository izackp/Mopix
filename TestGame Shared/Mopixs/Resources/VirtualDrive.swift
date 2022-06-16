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

/*
    api example:
 
    virtualDrive.mount("gameDir/basegame_1.0.1/")
    virtualDrive.mount("assets.zip")
 
    //ways to access files:
    "assets://randomImage.png"
    "basegame://ArtAssets/randomImage.png" //Via direct
    "/ArtAssets/randomImage.png" //Via virtual drive (All mounted drives are merged into one file system)
    "randomImage.png" //Via search
 
    

    storage is the name of the package:
    virtualDrive.writeStream("cache","/save.dat", stream)
    virtualDrive.writeStream(<MountedDirInstance>,"/save.dat", stream)
    virtualDrive.writeStream("vd://basegame.1.1.0/packagesave.dat", stream)
    virtualDrive.writeStream("vd://basegame/packagesave.dat", stream)
    ^ same for read
    virtualDrive.listMountedDir()
    virtualDrive.filesWithName("AnyName")
    virtualDrive.filesInDirectory("storage", "/cache/")
    virtualDrive.filesInDirectory(<MountedDir>,"/cache/")
    virtualDrive.filesInDirectory("/cache/")
    virtualDrive.directoriesInDirectory("storage", "/cache/")
    virtualDrive.directoriesInDirectory(<MountedDir>,"/cache/")
    virtualDrive.directoriesInDirectory("/cache/")
           
    The user directory will probably hold packages. Downloaded or created...
    
*/

// Huge structs make array resizing and data passing slower
public class MountedFile {
    internal init(name: Substring, ext: Substring, dir: Substring, path: Substring, mountPoint: MountedDir) {
        self.name = name
        self.ext = ext
        self.dir = dir
        self.path = path
        self.mountPoint = mountPoint
    }
    
    let name: Substring
    let ext: Substring
    let dir: Substring
    let path: Substring
    let mountPoint: MountedDir
}


public class VirtualDrive {
    internal init(_ listMountedDirectories: Arr<MountedDir> = Arr<MountedDir>()) {
        self.listMountedDirectories = listMountedDirectories
    }
    
    var listMountedDirectories: Arr<MountedDir> //Should be prioritized
    func findMountedDir(_ name: String) -> MountedDir? {
        for eachDir in self.listMountedDirectories {
            if (eachDir.meta.name == name) {
                return eachDir
            }
        }
        return nil
    }
            
    func mountPath(path:URL, mountDir:Substring = "/") async throws {
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
    
    func itemsInDirectory(_ mountedDir:MountedDir, _ path: String) throws -> [URL] {
        guard let dir = listMountedDirectories.first(where: {$0 === mountedDir}) else { throw GenericError("Mounted Dir does not belong to this virtual drive")}
        return dir.itemsInDirectory(path)
    }
    
    func itemsInDirectory(_ mountName:String, _ path: String) throws -> [URL] {
        guard let dir = listMountedDirectories.first(where: {$0.meta.name == mountName}) else { throw GenericError("Mounted directory with name \(mountName) not found")}
        return dir.itemsInDirectory(path)
    }
    
    func itemsInDirectory(_ path: String) -> [URL] {
        var items:[URL] = []
        for eachMD in listMountedDirectories {
            items.append(contentsOf: eachMD.itemsInDirectory(path))
        }
        return items
    }
    
    func urlForFileName(_ name:String) -> URL? {
        for eachMD in listMountedDirectories {
            if let result = eachMD.urlForName(name) {
                return result
            }
        }
        return nil
    }
    
    func urlForPath(_ path:String) -> URL? {
        for eachMD in listMountedDirectories {
            if let result = eachMD.urlForPath(path) {
                return result
            }
        }
        return nil
    }
    
    //Null if not found
    func readFile(_ url:URL) throws -> Data? {
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
