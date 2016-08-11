//
//  LCNull.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 4/23/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation

/**
 LeanCloud null type.

 A LeanCloud data type represents null value.

 - note: This type is not a singleton type, because Swift does not support singleton well currently.
 */
public class LCNull: NSObject, LCType, LCTypeExtension {
    public override init() {
        super.init()
    }

    public required init?(coder aDecoder: NSCoder) {
        /* Nothing to decode. */
    }

    public func encode(with aCoder: NSCoder) {
        /* Nothing to encode. */
    }

    public func copy(with zone: NSZone?) -> AnyObject {
        return LCNull()
    }

    public override func isEqual(_ object: AnyObject?) -> Bool {
        return object === self || object is LCNull
    }

    public var JSONValue: AnyObject {
        return NSNull()
    }

    public var JSONString: String {
        return ObjectProfiler.getJSONString(self)
    }

    var LCONValue: AnyObject? {
        return NSNull()
    }

    static func instance() throws -> LCType {
        return LCNull()
    }

    func forEachChild(_ body: @noescape (child: LCType) -> Void) {
        /* Nothing to do. */
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
