//
//  Utility.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 3/25/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation

class Utility {
    static func uuid() -> String {
        let uuid = NSUUID().uuidString
        return (uuid as NSString).replacingOccurrences(of: "-", with: "").lowercased()
    }

    static func JSONString(_ object: AnyObject) -> String {
        let data = try! JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions(rawValue: 0))
        return String(data: data, encoding: String.Encoding.utf8)!
    }
}
