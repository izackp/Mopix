//
//  Version.swift
//  TestGame
//
//  Created by Isaac Paul on 4/26/22.
//

import Foundation

public struct Version: ExpressibleByIntegerLiteral, Equatable, LosslessStringConvertible {
    
    var _rawValue: UInt32
    public typealias IntegerLiteralType = UInt32
    public init(integerLiteral value: UInt32) {
        self._rawValue = value
    }
    
    public static let zero = Version(integerLiteral: 0)
    
    //
    fileprivate let unexpectedValue = "Unexpected value for parameter: "
    public init(_ major: Int = 0, _ minor: Int = 0, _ revision: Int = 0) throws {
        if (major < 0 || major >= 256) {
            throw GenericError("\(unexpectedValue)major { \(major)")
        }
        
        if (minor < 0 || minor >= 4096) {
            throw GenericError("\(unexpectedValue)minor { \(minor)")
        }
        
        if (revision < 0 || revision >= 4096) {
            throw GenericError("\(unexpectedValue)revision { \(revision)")
        }
        
        self._rawValue = 0
        setMajor_(major)
        setMinor_(minor)
        setRevision_(revision)
    }
    
    public init?(_ description: String) {
        let subStr = description.substring(from: 0)
        var scanner = StringScanner(span: subStr, pos: 0, dir: 1)
        self._rawValue = 0
        do {
            let major = Int(try scanner.readInt32())
            setMajor_(major)
        } catch {
            return nil
        }
        do {
            try scanner.expect(c: ".")
            let minor = Int(try scanner.readInt32())
            setMinor_(minor)
            try scanner.expect(c: ".")
            let revision = Int(try scanner.readInt32())
            setRevision_(revision)
        } catch { }
    }
    
    // Major
    public func getMajor() -> Int {
        return Int(_rawValue & 0xFF000000) >> 24
    }
    
    public mutating func setMajor_(_ value: Int) {
        assert(value < 256 && value >= 0)
        _rawValue = (UInt32(value) << 24) | (_rawValue & 0x00FFFFFF)
    }
    
    public mutating func setMajor(_ value: Int) throws {
        if (value >= 256 || value < 0) {
            throw GenericError("Value is beyond limit of 255")
        }
        _rawValue = (UInt32(value) << 24) | (_rawValue & 0x00FFFFFF)
    }
    
    // Minor
    public func getMinor() -> Int {
        return Int(_rawValue & 0x00FFF000) >> 12
    }
    
    public mutating func setMinor_(_ value: Int) {
        assert(value < 4096 && value >= 0)
        _rawValue = (UInt32(value) << 12) | (_rawValue & 0xFF000FFF)
    }
    
    public mutating func setMinor(_ value: Int) throws {
        if (value >= 4096 || value < 0) {
            throw GenericError("Value is beyond limit of 4095")
        }
        _rawValue = (UInt32(value) << 12) | (_rawValue & 0xFF000FFF)
    }
    
    // Revision
    public func getRevision() -> Int {
        return Int(_rawValue & 0x00000FFF)
    }
    
    public mutating func setRevision_(_ value: Int) {
        assert(value < 4096 && value >= 0)
        _rawValue = UInt32(value) | (_rawValue & 0xFFFFF000)
    }
    
    public mutating func setRevision(_ value: Int) throws {
        if (value >= 4096 || value < 0) {
            throw GenericError("Value is beyond limit of 4095")
        }
        _rawValue = UInt32(value) | (_rawValue & 0xFFFFF000)
    }
    
    public var description: String {
        return toString()
    }
    
    public func toString() -> String {
        return "\(getMajor()).\(getMinor()).\(getRevision())"
    }
}

