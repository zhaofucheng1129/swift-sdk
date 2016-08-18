//
//  CQLClient.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 5/30/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation

/**
 A type represents the result value of CQL execution.
 */
public class LCCQLValue {
    let response: LCResponse

    init(response: LCResponse) {
        self.response = response
    }

    var results: [[String: AnyObject]] {
        return (response.results as? [[String: AnyObject]]) ?? []
    }

    var className: String {
        return (response["className"] as? String) ?? LCObject.objectClassName()
    }

    /**
     Get objects for object query.
     */
    public var objects: [LCObject] {
        let results   = self.results
        let className = self.className

        return results.map { dictionary in
            ObjectProfiler.object(dictionary: dictionary, className: className)
        }
    }

    /**
     Get count value for count query.
     */
    public var count: Int {
        return response.count
    }
}

/**
 CQL client.

 CQLClient allow you to use CQL (Cloud Query Language) to make CRUD for object.
 */
public class LCCQLClient {
    static let endpoint = "cloudQuery"

    /**
     Assemble parameters for CQL execution.

     - parameter CQL:        The CQL statement.
     - parameter parameters: The parameters for placeholders in CQL statement.

     - returns: The parameters for CQL execution.
     */
    static func parameters(_ CQL: String, parameters: [AnyObject]) -> [String: AnyObject] {
        var result = ["cql": CQL]

        if !parameters.isEmpty {
            result["pvalues"] = Utility.JSONString(ObjectProfiler.LCONValue(parameters))
        }

        return result
    }

    /**
     Execute CQL statement synchronously.

     - parameter CQL:        The CQL statement to be executed.
     - parameter parameters: The parameters for placeholders in CQL statement.

     - returns: The result of CQL statement.
     */
    public static func execute(_ CQL: String, parameters: [AnyObject] = []) -> LCCQLResult {
        let parameters = self.parameters(CQL, parameters: parameters)
        let response   = RESTClient.request(.get, endpoint, parameters: parameters)

        return LCCQLResult(response: response)
    }
}
