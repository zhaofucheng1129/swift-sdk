//
//  LCDictionary.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 2/27/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation

/**
 LeanCloud dictionary type.

 It is a wrapper of `Swift.Dictionary` type, used to store a dictionary value.
 */
public final class LCDictionary: NSObject, LCType, LCTypeExtension, Sequence, ExpressibleByDictionaryLiteral {
    public private(set) var value: [String: LCType] = [:]

    public override init() {
        super.init()
    }

    public convenience init(_ value: [String: LCType]) {
        self.init()
        self.value = value
    }

    public convenience required init(dictionaryLiteral elements: (String, LCType)...) {
        self.init(Dictionary<String, LCType>(elements: elements))
    }

    public convenience init(unsafeObject: [String: AnyObject]) {
        self.init()
        value = unsafeObject.mapValue { value in
            try! ObjectProfiler.object(JSONValue: value)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        value = (aDecoder.decodeObject(forKey: "value") as? [String: LCType]) ?? [:]
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(value, forKey: "value")
    }

    public func copy(with zone: NSZone?) -> AnyObject {
        return LCDictionary(value)
    }

    public override func isEqual(_ object: AnyObject?) -> Bool {
        if object === self {
            return true
        } else if let object = object as? LCDictionary {
            let lhs: AnyObject = value
            let rhs: AnyObject = object.value

            return lhs.isEqual(rhs)
        } else {
            return false
        }
    }

    public func makeIterator() -> DictionaryIterator<String, LCType> {
        return value.makeIterator()
    }

    public subscript(key: String) -> LCType? {
        get { return value[key] }
        set { value[key] = newValue }
    }

    public var JSONValue: AnyObject {
        return value.mapValue { value in value.JSONValue }
    }

    public var JSONString: String {
        return ObjectProfiler.getJSONString(self)
    }

    var LCONValue: AnyObject? {
        return value.mapValue { value in (value as! LCTypeExtension).LCONValue! }
    }

    static func instance() -> LCType {
        return self.init([:])
    }

    func forEachChild(_ body: @noescape (child: LCType) -> Void) {
        forEach { body(child: $1) }
    }

    func add(_ other: LCType) throws -> LCType {
        throw LCError(code: .invalidType, reason: "Object cannot be added.")
    }

    func concatenate(_ other: LCType, unique: Bool) throws -> LCType {
        throw LCError(code: .invalidType, reason: "Object cannot be concatenated.")
    }

    func differ(_ other: LCType) throws -> LCType {
        throw LCError(code: .invalidType, reason: "Object cannot be differed.")
    }
}
