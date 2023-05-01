//
//  Weak.swift
//  TestGame
//
//  Created by Isaac Paul on 9/22/22.
//

import Foundation
//Note: We do a bit of type erasing otherwise we won't be able to support protocols or non-concrete types

public final class Weak<Value> {
    /// The instance being stored.
    private weak var weakValue: AnyObject?
    /// Interface to access the weak value (if it is there).
    public var value: Value? { return self.weakValue as? Value }
    /// Boolean indicating whether the value has already being deallocated or not.
    public var isEmpty: Bool { return self.weakValue == nil }
    
    /// Creates a wrapper for a concrete value.
    public init(_ value: Value) {
        let asAny:Any = value
        if (type(of: asAny) is AnyClass) {
            self.weakValue = value as AnyObject
        } else {
            self.weakValue = nil
            assert(true, "Instance must be an obj")
        }
    }
    
    /// Creates a wrapper for an optional value (it can be `nil`).
    public init(_ value: Value?) {
        if let value = value {
            let asAny:Any = value
            if (type(of: asAny) is AnyClass) {
                self.weakValue = value as AnyObject
            } else {
                self.weakValue = nil
                assert(true, "Instance must be an obj")
            }
        } else {
            self.weakValue = nil
        }
    }
}

/// An ordered, random-access collection of weak elements.
/// - seealso: Swift.Array
public struct WeakArray<T> {
    /// Internal storage for the weak wrappers.
    //private var test = Weak<T>([])
    private var items = [Weak<T>]()
    
    /// Creates a new empty `WeakArray`.
    public init() {
        self.items = []
    }
    
    /// Creates a new instance of a collection containing the elements of a sequence.
    public init<S:Sequence>(_ elements: S) where T == S.Element {
        self.items = elements.map { Weak($0) }
    }
    
    /// An array representation of all weak values (including those that are `nil`).
    public var array: [T?] {
        return self.items.map { $0.value }
    }
    
    /// An array representation of all non-empty elements.
    public var values: [T] {
        return self.items.compactMap { $0.value }
    }
    
    /// Reap the array of elements that are `nil`.
    public mutating func clean() {
        let result = self.items.filter { !$0.isEmpty }
        self.items = result
    }
}

extension WeakArray: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: T...) {
        self.items = elements.map { Weak($0) }
    }
}

extension WeakArray: Collection {
    public var startIndex: Int { return items.startIndex }
    public var endIndex: Int { return items.endIndex }
    
    public subscript(_ index: Int) -> T? {
        return items[index].value
    }
    
    public func index(after i: Int) -> Int {
        return items.index(after: i)
    }
}

extension WeakArray {
    /// Adds a new element at the end of the array.
    public mutating func append(_ newElement: T?) {
        self.items.append(Weak(newElement))
    }
    
    /// Removes and returns the element at the specified position.
    @discardableResult
    public mutating func remove(at position: Int) -> T? {
        return self.items.remove(at: position).value
    }
    
    /// Removes the element within the array that match triple equility (`===`) with the element in the argument.
    @discardableResult
    public mutating func remove(element: Element) -> Element? {
        guard let index = self.index(of: element) else { return nil }
        return self.remove(at: index)
    }
}

extension WeakArray {
    /// Returns the index of the element matching the triple equility (`===`) with the element in the argument.
    fileprivate func index(of element: Element) -> Int? {
        let asAny = element as AnyObject
        for (index, wrapper) in self.items.enumerated() {
            guard let value = wrapper.value, value as AnyObject === asAny else { continue }
            return index
        }
        return nil
    }
}

