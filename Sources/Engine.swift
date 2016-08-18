//
//  Engine.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 5/10/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation

public final class LCEngine {
    typealias Parameters = [String: AnyObject]

    /**
     Call LeanEngine function.

     - parameter function: The function name to be called.

     - returns: The result of function call.
     */
    public static func call(_ function: String) -> LCOptionalResult {
        return call(function, parameters: nil)
    }

    /**
     Call LeanEngine function with parameters.

     - parameter function:   The function name.
     - parameter parameters: The parameters to be passed to remote function.

     - returns: The result of function all.
     */
    public static func call(_ function: String, parameters: [String: AnyObject]) -> LCOptionalResult {
        return call(function, parameters: ObjectProfiler.LCONValue(parameters) as? Parameters)
    }

    /**
     Call LeanEngine function with parameters.

     The parameters will be serialized to JSON representation.

     - parameter function:   The function name.
     - parameter parameters: The parameters to be passed to remote function.

     - returns: The result of function all.
     */
    public static func call(_ function: String, parameters: LCDictionary) -> LCOptionalResult {
        return call(function, parameters: ObjectProfiler.LCONValue(parameters) as? Parameters)
    }

    /**
     Call LeanEngine function with parameters.

     The parameters will be serialized to JSON representation.

     - parameter function:   The function name.
     - parameter parameters: The parameters to be passed to remote function.

     - returns: The result of function all.
     */
    public static func call(_ function: String, parameters: LCObject) -> LCOptionalResult {
        return call(function, parameters: ObjectProfiler.LCONValue(parameters) as? Parameters)
    }

    /**
     Call LeanEngine function with parameters.

     - parameter function:   The function name.
     - parameter parameters: The JSON parameters to be passed to remote function.

     - returns: The result of function call.
     */
    static func call(_ function: String, parameters: Parameters?) -> LCOptionalResult {
        let response = RESTClient.request(.post, "call/\(function)", parameters: parameters)

        return response.optionalResult("result")
    }
}
