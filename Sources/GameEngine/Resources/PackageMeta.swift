//
//  PackageMeta.swift
//  TestGame
//
//  Created by Isaac Paul on 9/23/22.
//

import Foundation

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
        return "\(name)_\(version.toString())"
    }
}
