//
//  LCArray.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 2/27/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation

/**
 LeanCloud list type.

 It is a wrapper of `Swift.Array` type, used to store a list of objects.
 */
public final class LCArray: NSObject, LCType, LCTypeExtension, Sequence, ExpressibleByArrayLiteral {
    public typealias Element = LCType

    public private(set) var value: [Element] = []

    public override init() {
        super.init()
    }

    public convenience init(_ value: [Element]) {
        self.init()
        self.value = value
    }

    public convenience required init(arrayLiteral elements: Element...) {
        self.init(elements)
    }

    public convenience init(unsafeObject: [AnyObject]) {
        self.init()
        value = unsafeObject.map { element in
            try! ObjectProfiler.object(JSONValue: element)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        value = (aDecoder.decodeObject(forKey: "value") as? [Element]) ?? []
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(value, forKey: "value")
    }

    public func copy(with zone: NSZone?) -> AnyObject {
        return LCArray(value)
    }

    public override func isEqual(_ object: AnyObject?) -> Bool {
        if object === self {
            return true
        } else if let object = object as? LCArray {
            let lhs: AnyObject = value
            let rhs: AnyObject = object.value

            return lhs.isEqual(rhs)
        } else {
            return false
        }
    }

    public func makeIterator() -> IndexingIterator<[Element]> {
        return value.makeIterator()
    }

    public subscript(index: Int) -> LCType? {
        get { return value[index] }
    }

    public var JSONValue: AnyObject {
        return value.map { element in element.JSONValue }
    }

    public var JSONString: String {
        return ObjectProfiler.getJSONString(self)
    }

    var LCONValue: AnyObject? {
        return value.map { element in (element as! LCTypeExtension).LCONValue! }
    }

    static func instance() -> LCType {
        return self.init([])
    }

    func forEachChild(_ body: @noescape (child: LCType) -> Void) {
        forEach { element in body(child: element) }
    }

    func add(_ other: LCType) throws -> LCType {
        throw LCError(code: .invalidType, reason: "Object cannot be added.")
    }

    func concatenate(_ other: LCType, unique: Bool) throws -> LCType {
        let result   = LCArray(value)
        let elements = (other as! LCArray).value

        result.concatenateInPlace(elements, unique: unique)

        return result
    }

    func concatenateInPlace(_ elements: [Element], unique: Bool) {
        value = unique ? (value +~ elements) : (value + elements)
    }

    func differ(_ other: LCType) throws -> LCType {
        let result   = LCArray(value)
        let elements = (other as! LCArray).value

        result.differInPlace(elements)

        return result
    }

    func differInPlace(_ elements: [Element]) {
        value = value - elements
    }
}
