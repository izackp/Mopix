//
//  StringScanner.swift
//  TestGame
//
//  Created by Isaac Paul on 4/27/22.
//

import Foundation

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
    
    subscript (r: ClosedRange<Int>) -> SubSequence {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        let range = start ..< end
        return self[range]
    }
    
    func index(offset: Int) -> Index {
        return self.index(startIndex, offsetBy: offset)
    }
    
    func substring(from: Int) -> SubSequence {
        let fromIndex = index(offset: from)
        return self[fromIndex...]
    }
    
    func substring(to: Int) -> SubSequence {
        let toIndex = index(offset: to)
        return self[..<toIndex]
    }
    
}

extension CharacterSet {
    func containsUnicodeScalars(of character: Character) -> Bool {
        return character.unicodeScalars.allSatisfy(contains(_:))
    }
}

public struct StringScanner {
    let span:Substring
    public var pos:Int
    var dir:Int
    
    public func checkPos() throws {
        if (pos < 0 || pos >= span.count) {
            throw GenericError("Current pos not in string: pos: \(pos) str: \(span)")
        }
    }
    
    public mutating func expect(c: Character) throws {
        try checkPos()
        let cAtPos = span[pos]
        if (cAtPos != c) {
            throw GenericError("Unexpected character: \(cAtPos) pos: \(pos) str: \(span)")
        }
        pos += dir
        return
    }
    
    public mutating func expect(set: CharacterSet) throws {
        try checkPos()
        let cAtPos = span[pos]
        if (set.containsUnicodeScalars(of: cAtPos) == false) {
            throw GenericError("Unexpected character: \(cAtPos) pos: \(pos) str: \(span)")
        }
        pos += dir
        return
    }
    
    public mutating func move(by: Int) -> Bool {
        let targetPos = pos + by
        if (targetPos < 0 || targetPos >= span.count) {
            return false
        }
        pos = targetPos
        return true
    }
    
    public mutating func skipAny(set: CharacterSet) {
        if (pos < 0 || pos >= span.count) {
            return
        }
        let start = pos
        let rStride:StrideThrough<Int>
        if (dir < 0) {
            rStride = stride(from:start, through:0, by:dir)
        } else {
            rStride = stride(from:start, through:span.count-1, by:dir)
        }
        for i in rStride {
            pos = i
            if (set.containsUnicodeScalars(of: span[i]) == false) {
                break
            }
        }
    }
    
    //Essentialy tries to consume a string to return. Pos stops at next character
    public mutating func readUntilMatch(set: CharacterSet, maxChars:Int) throws -> Substring {
        try checkPos()
        let start = pos
        var total = 0
        //Extra read for simpler code
        if (set.containsUnicodeScalars(of: span[start])) {
            throw GenericError("Unexpected character: \(span[start]) pos: \(pos) str: \(span)")
        }
        let rStride:StrideThrough<Int>
        if (dir < 0) {
            rStride = stride(from:start, through:0, by:dir)
        } else {
            rStride = stride(from:start, through:span.count-1, by:dir)
        }
        for i in rStride {
            pos = i
            if (set.containsUnicodeScalars(of: span[i]) || total >= maxChars) {
                break
            }
            total += 1
        }
        let endPos = pos - dir
        if (dir < 0) {
            return span[endPos...start]
        }
        return span[start...endPos]
    }
    
    public mutating func readWhileMatching(set: CharacterSet, maxChars:Int) throws -> Substring {
        try checkPos()
        let start = pos
        var total = 0
        //Extra read for simpler code
        if (set.containsUnicodeScalars(of: span[start]) == false) {
            throw GenericError("Unexpected character: \(span[start]) pos: \(pos) str: \(span)")
        }
        let rStride:StrideThrough<Int>
        if (dir < 0) {
            rStride = stride(from:start, through:0, by:dir)
        } else {
            rStride = stride(from:start, through:span.count-1, by:dir)
        }
        for i in rStride {
            pos = i
            if (set.containsUnicodeScalars(of: span[i]) == false || total >= maxChars) {
                break
            }
            total += 1
        }
        let endPos = pos - dir
        if (dir < 0) {
            return span[endPos...start]
        }
        return span[start...endPos]
    }
    
    let IntChars = CharacterSet(charactersIn: "-").union(CharacterSet.decimalDigits)
    //let Separators = CharacterSet(charactersIn: "-").union(CharacterSet.decimalDigits)

    //Ex: -2147483648
    public mutating func readInt32() throws -> Int32 {
        let strInt = try readWhileMatching(set: CharacterSet.decimalDigits, maxChars: 10)
        guard let value = Int32(strInt) else {
            throw GenericError("Unable to parse int from str: \(strInt)")
        }
        return value
    }
}

extension Substring {
    
    //TODO: Rename
    func lastPathPart() throws -> Substring {
        let pos = self.count - 1
        var scanner = StringScanner(span: self, pos: pos, dir: -1)
        scanner.skipAny(set: OS.pathSeparatorSet)
        let result = try scanner.readUntilMatch(set: OS.pathSeparatorSet, maxChars: 255)
        return result
    }
}

