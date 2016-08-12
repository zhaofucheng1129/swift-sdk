//
//  Query.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 4/19/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation

/**
 Query defines a query for objects.
 */
final public class LCQuery: NSObject, NSCopying, NSCoding {
    /// Object class name.
    public let objectClassName: String

    /// The limit on the number of objects to return.
    public var limit: Int?

    /// The number of objects to skip before returning.
    public var skip: Int?

    /// Included keys.
    private var includedKeys: Set<String> = []

    /// Selected keys.
    private var selectedKeys: Set<String> = []

    /// Equality table.
    private var equalityTable: [String: LCType] = [:]

    /// Equality key-value pairs.
    private var equalityPairs: [[String: LCType]] {
        return equalityTable.map { [$0: $1] }
    }

    /// Ordered keys.
    private var orderedKeys: String?

    /// Dictionary of constraints indexed by key.
    /// Note that it may contains LCType or Query value.
    private var constraintDictionary: [String: AnyObject] = [:]

    /// Extra parameters for query request.
    var extraParameters: [String: AnyObject]?

    /// LCON representation of query.
    var LCONValue: [String: AnyObject] {
        var dictionary: [String: AnyObject] = [:]

        dictionary["className"] = objectClassName

        if !constraintDictionary.isEmpty {
            dictionary["where"] = ObjectProfiler.LCONValue(constraintDictionary)
        }
        if !includedKeys.isEmpty {
            dictionary["include"] = includedKeys.joined(separator: ",")
        }
        if !selectedKeys.isEmpty {
            dictionary["keys"] = selectedKeys.joined(separator: ",")
        }
        if let orderedKeys = orderedKeys {
            dictionary["order"] = orderedKeys
        }
        if let limit = limit {
            dictionary["limit"] = limit
        }
        if let skip = skip {
            dictionary["skip"] = skip
        }

        if let extraParameters = extraParameters {
            extraParameters.forEach { (key, value) in
                dictionary[key] = value
            }
        }

        return dictionary
    }

    /// Parameters for query request.
    private var parameters: [String: AnyObject] {
        var parameters = LCONValue

        /* Encode where field to string. */
        if let object = parameters["where"] {
            parameters["where"] = Utility.JSONString(object)
        }

        return parameters
    }

    /// The dispatch queue for network request task.
    static let backgroundQueue = DispatchQueue(label: "LeanCloud.Query", attributes: .concurrent)

    /**
     Constraint for key.
     */
    public enum Constraint {
        case included
        case selected
        case existed
        case notExisted

        case equalTo(LCType)
        case notEqualTo(LCType)
        case lessThan(LCType)
        case lessThanOrEqualTo(LCType)
        case greaterThan(LCType)
        case greaterThanOrEqualTo(LCType)

        case containedIn(LCArray)
        case notContainedIn(LCArray)
        case containedAllIn(LCArray)
        case equalToSize(Int)

        case nearbyPoint(LCGeoPoint)
        case nearbyPointWithRange(origin: LCGeoPoint, from: LCGeoPoint.Distance?, to: LCGeoPoint.Distance?)
        case nearbyPointWithRectangle(southwest: LCGeoPoint, northeast: LCGeoPoint)

        case matchedQuery(LCQuery)
        case notMatchedQuery(LCQuery)
        case matchedQueryAndKey(query: LCQuery, key: String)
        case notMatchedQueryAndKey(query: LCQuery, key: String)

        case matchedPattern(String, option: String?)
        case matchedSubstring(String)
        case prefixedBy(String)
        case suffixedBy(String)

        case relatedTo(LCObject)

        case ascending
        case descending
    }

    var endpoint: String {
        return RESTClient.endpoint(objectClassName)
    }

    /**
     Construct query with class name.

     - parameter objectClassName: The class name to query.
     */
    public init(className: String) {
        self.objectClassName = className
    }

    public func copy(with zone: NSZone?) -> AnyObject {
        let query = LCQuery(className: objectClassName)

        query.includedKeys  = includedKeys
        query.selectedKeys  = selectedKeys
        query.equalityTable = equalityTable
        query.constraintDictionary = constraintDictionary
        query.extraParameters = extraParameters
        query.limit = limit
        query.skip  = skip

        return query
    }

    public required init?(coder aDecoder: NSCoder) {
        objectClassName = aDecoder.decodeObject(forKey: "objectClassName") as! String
        includedKeys    = aDecoder.decodeObject(forKey: "includedKeys") as! Set<String>
        selectedKeys    = aDecoder.decodeObject(forKey: "selectedKeys") as! Set<String>
        equalityTable   = aDecoder.decodeObject(forKey: "equalityTable") as! [String: LCType]
        constraintDictionary = aDecoder.decodeObject(forKey: "constraintDictionary") as! [String: AnyObject]
        extraParameters = aDecoder.decodeObject(forKey: "extraParameters") as? [String: AnyObject]
        limit = aDecoder.decodeObject(forKey: "limit") as? Int
        skip  = aDecoder.decodeObject(forKey: "skip") as? Int
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(objectClassName, forKey: "objectClassName")
        aCoder.encode(includedKeys, forKey: "includedKeys")
        aCoder.encode(selectedKeys, forKey: "selectedKeys")
        aCoder.encode(equalityTable, forKey: "equalityTable")
        aCoder.encode(constraintDictionary, forKey: "constraintDictionary")

        if let extraParameters = extraParameters {
            aCoder.encode(extraParameters, forKey: "extraParameters")
        }
        if let limit = limit {
            aCoder.encode(limit, forKey: "limit")
        }
        if let skip = skip {
            aCoder.encode(skip, forKey: "skip")
        }
    }

    /**
     Add constraint in query.

     - parameter constraint: The constraint.
     */
    public func whereKey(_ key: String, _ constraint: Constraint) {
        var dictionary: [String: AnyObject]?

        switch constraint {
        /* Key matching. */
        case .included:
            includedKeys.insert(key)
        case .selected:
            selectedKeys.insert(key)
        case .existed:
            dictionary = ["$exists": true]
        case .notExisted:
            dictionary = ["$exists": false]

        /* Equality matching. */
        case let .equalTo(value):
            equalityTable[key] = value
            constraintDictionary["$and"] = equalityPairs
        case let .notEqualTo(value):
            dictionary = ["$ne": value]
        case let .lessThan(value):
            dictionary = ["$lt": value]
        case let .lessThanOrEqualTo(value):
            dictionary = ["$lte": value]
        case let .greaterThan(value):
            dictionary = ["$gt": value]
        case let .greaterThanOrEqualTo(value):
            dictionary = ["$gte": value]

        /* Array matching. */
        case let .containedIn(array):
            dictionary = ["$in": array]
        case let .notContainedIn(array):
            dictionary = ["$nin": array]
        case let .containedAllIn(array):
            dictionary = ["$all": array]
        case let .equalToSize(size):
            dictionary = ["$size": size]

        /* Geography point matching. */
        case let .nearbyPoint(point):
            dictionary = ["$nearSphere": point]
        case let .nearbyPointWithRange(point, min, max):
            var value: [String: AnyObject] = ["$nearSphere": point]
            if let min = min { value["$minDistanceIn\(min.unit.rawValue)"] = min.value }
            if let max = max { value["$maxDistanceIn\(max.unit.rawValue)"] = max.value }
            dictionary = value
        case let .nearbyPointWithRectangle(southwest, northeast):
            dictionary = ["$within": ["$box": [southwest, northeast]]]

        /* Query matching. */
        case let .matchedQuery(query):
            dictionary = ["$inQuery": query]
        case let .notMatchedQuery(query):
            dictionary = ["$notInQuery": query]
        case let .matchedQueryAndKey(query, key):
            dictionary = ["$select": ["query": query, "key": key]]
        case let .notMatchedQueryAndKey(query, key):
            dictionary = ["$dontSelect": ["query": query, "key": key]]

        /* String matching. */
        case let .matchedPattern(pattern, option):
            dictionary = ["$regex": pattern, "$options": option ?? ""]
        case let .matchedSubstring(string):
            dictionary = ["$regex": "\(string.regularEscapedString)"]
        case let .prefixedBy(string):
            dictionary = ["$regex": "^\(string.regularEscapedString)"]
        case let .suffixedBy(string):
            dictionary = ["$regex": "\(string.regularEscapedString)$"]

        case let .relatedTo(object):
            constraintDictionary["$relatedTo"] = ["object": object, "key": key]

        case .ascending:
            appendOrderedKey(key)
        case .descending:
            appendOrderedKey("-\(key)")
        }

        if let dictionary = dictionary {
            addConstraint(key, dictionary)
        }
    }

    /**
     Validate query class name.

     - parameter query: The query to be validated.
     */
    func validateClassName(_ query: LCQuery) {
        guard query.objectClassName == objectClassName else {
            Exception.raise(.inconsistency, reason: "Different class names.")
            return
        }
    }

    /**
     Get logic AND of another query.

     Note that it only combine constraints of two queries, the limit and skip option will be discarded.

     - parameter query: The another query.

     - returns: The logic AND of two queries.
     */
    public func and(_ query: LCQuery) -> LCQuery {
        validateClassName(query)

        let result = LCQuery(className: objectClassName)

        result.constraintDictionary["$and"] = [self.constraintDictionary, query.constraintDictionary]

        return result
    }

    /**
     Get logic OR of another query.

     Note that it only combine constraints of two queries, the limit and skip option will be discarded.

     - parameter query: The another query.

     - returns: The logic OR of two queries.
     */
    public func or(_ query: LCQuery) -> LCQuery {
        validateClassName(query)

        let result = LCQuery(className: objectClassName)

        result.constraintDictionary["$or"] = [self.constraintDictionary, query.constraintDictionary]

        return result
    }

    /**
     Append ordered key to ordered keys string.

     - parameter orderedKey: The ordered key with optional '-' prefixed.
     */
    func appendOrderedKey(_ orderedKey: String) {
        if let orderedKeys = orderedKeys {
            self.orderedKeys = orderedKeys + orderedKey
        } else {
            self.orderedKeys = orderedKey
        }
    }

    /**
     Add a constraint for key.

     - parameter key:        The key on which the constraint to be added.
     - parameter dictionary: The constraint dictionary for key.
     */
    func addConstraint(_ key: String, _ dictionary: [String: AnyObject]) {
        constraintDictionary[key] = dictionary
    }

    /**
     Transform JSON results to objects.

     - parameter results: The results return by query.

     - returns: An array of LCObject objects.
     */
    func processResults<T: LCObject>(_ results: [AnyObject], className: String?) -> [T] {
        return results.map { dictionary in
            let object = ObjectProfiler.object(className: className ?? self.objectClassName) as! T

            if let dictionary = dictionary as? [String: AnyObject] {
                ObjectProfiler.updateObject(object, dictionary)
            }

            return object
        }
    }

    /**
     Asynchronize task into background queue.

     - parameter task:       The task to be performed.
     - parameter completion: The completion closure to be called on main thread after task finished.
     */
    static func asynchronize<Result>(_ task: () -> Result, completion: (Result) -> Void) {
        Utility.asynchronize(task, backgroundQueue, completion)
    }

    /**
     Query objects synchronously.

     - returns: The result of the query request.
     */
    public func find<T: LCObject>() -> LCQueryResult<T> {
        let response = RESTClient.request(.get, endpoint, parameters: parameters)

        if let error = response.error {
            return .failure(error: error)
        } else {
            let className = response.value?["className"] as? String
            let objects: [T] = processResults(response.results, className: className)

            return .success(objects: objects)
        }
    }

    /**
     Query objects asynchronously.

     - parameter completion: The completion callback closure.
     */
    public func find<T: LCObject>(_ completion: (LCQueryResult<T>) -> Void) {
        LCQuery.asynchronize({ self.find() }) { result in
            completion(result)
        }
    }

    /**
     Get first object of query synchronously.

     - note: All query conditions other than `limit` will take effect for current request.

     - returns: The object result of query.
     */
    public func getFirst<T: LCObject>() -> LCObjectResult<T> {
        let query = copy() as! LCQuery

        query.limit = 1

        let result: LCQueryResult<T> = query.find()

        switch result {
        case let .success(objects):
            guard let object = objects.first else {
                return .failure(error: LCError(code: .notFound, reason: "Object not found."))
            }

            return .success(object: object)
        case let .failure(error):
            return .failure(error: error)
        }
    }

    /**
     Get first object of query asynchronously.

     - parameter completion: The completion callback closure.
     */
    public func getFirst<T: LCObject>(_ completion: (LCObjectResult<T>) -> Void) {
        LCQuery.asynchronize({ self.getFirst() }) { result in
            completion(result)
        }
    }

    /**
     Get object by object ID synchronously.

     - parameter objectId: The object ID.

     - returns: The object result of query.
     */
    public func get<T: LCObject>(_ objectId: String) -> LCObjectResult<T> {
        let query = copy() as! LCQuery

        query.whereKey("objectId", .equalTo(LCString(objectId)))

        return query.getFirst()
    }

    /**
     Get object by object ID asynchronously.

     - parameter objectId:   The object ID.
     - parameter completion: The completion callback closure.
     */
    public func get<T: LCObject>(_ objectId: String, completion: (LCObjectResult<T>) -> Void) {
        LCQuery.asynchronize({ self.get(objectId) }) { result in
            completion(result)
        }
    }

    /**
     Count objects synchronously.

     - returns: The result of the count request.
     */
    public func count() -> LCCountResult {
        var parameters = self.parameters

        parameters["count"] = 1
        parameters["limit"] = 0

        let response = RESTClient.request(.get, endpoint, parameters: parameters)
        let result = LCCountResult(response: response)

        return result
    }

    /**
     Count objects asynchronously.

     - parameter completion: The completion callback closure.
     */
    public func count(_ completion: (LCCountResult) -> Void) {
        LCQuery.asynchronize({ self.count() }) { result in
            completion(result)
        }
    }
}
