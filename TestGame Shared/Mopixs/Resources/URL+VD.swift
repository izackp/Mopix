//
//  URL+VD.swift
//  TestGame
//
//  Created by Isaac Paul on 9/23/22.
//

import Foundation

extension URL {
    func isDirectory() throws -> Bool {
        let res = try resourceValues(forKeys: [.isDirectoryKey])
        return res.isDirectory == true
    }
}

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
