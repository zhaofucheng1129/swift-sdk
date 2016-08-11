//
//  LCData.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 4/1/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation

/**
 LeanCloud data type.

 This type can be used to represent a byte buffers.
 */
public final class LCData: NSObject, LCType, LCTypeExtension {
    public private(set) var value: Data = Data()

    var base64EncodedString: String {
        return value.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }

    static func dataFromString(_ string: String) -> Data? {
        return Data(base64Encoded: string, options: NSData.Base64DecodingOptions(rawValue: 0))
    }

    public override init() {
        super.init()
    }

    public convenience init(_ data: Data) {
        self.init()
        value = data
    }

    init?(base64EncodedString: String) {
        guard let data = LCData.dataFromString(base64EncodedString) else {
            return nil
        }

        value = data
    }

    init?(dictionary: [String: AnyObject]) {
        guard let type = dictionary["__type"] as? String else {
            return nil
        }
        guard let dataType = RESTClient.DataType(rawValue: type) else {
            return nil
        }
        guard case dataType = RESTClient.DataType.Bytes else {
            return nil
        }
        guard let base64EncodedString = dictionary["base64"] as? String else {
            return nil
        }
        guard let data = LCData.dataFromString(base64EncodedString) else {
            return nil
        }

        value = data
    }

    public required init?(coder aDecoder: NSCoder) {
        value = (aDecoder.decodeObject(forKey: "value") as? Data) ?? Data()
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(value, forKey: "value")
    }

    public func copy(with zone: NSZone?) -> AnyObject {
        return LCData((value as NSData).copy() as! Data)
    }

    public override func isEqual(_ another: AnyObject?) -> Bool {
        if another === self {
            return true
        } else if let another = another as? LCData {
            return (another.value as NSData).isEqual(to: value)
        } else {
            return false
        }
    }

    public var JSONValue: AnyObject {
        return [
            "__type": "Bytes",
            "base64": base64EncodedString
        ]
    }

    public var JSONString: String {
        return ObjectProfiler.getJSONString(self)
    }

    var LCONValue: AnyObject? {
        return JSONValue
    }

    static func instance() -> LCType {
        return self.init()
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
