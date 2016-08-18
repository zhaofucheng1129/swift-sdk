//
//  RESTClient.swift
//  LeanCloud
//
//  Created by Tang Tianyong on 3/30/16.
//  Copyright © 2016 LeanCloud. All rights reserved.
//

import Foundation
import Akara

/**
 LeanCloud REST client.

 This class manages requests for LeanCloud REST API.
 */
class RESTClient {
    /// HTTP Method.
    enum Method: String {
        case get
        case post
        case put
        case delete
    }

    /// Data type.
    enum DataType: String {
        case object   = "Object"
        case pointer  = "Pointer"
        case relation = "Relation"
        case geoPoint = "GeoPoint"
        case bytes    = "Bytes"
        case date     = "Date"
    }

    /// Reserved key.
    class ReservedKey {
        static let op         = "__op"
        static let internalId = "__internalId"
        static let children   = "__children"
    }

    /// Header field name.
    class HeaderFieldName {
        static let id         = "X-LC-Id"
        static let signature  = "X-LC-Sign"
        static let session    = "X-LC-Session"
        static let production = "X-LC-Prod"
        static let userAgent  = "User-Agent"
        static let accept     = "Accept"
    }

    /// REST API version.
    static let apiVersion = "1.1"

    /// Default timeout interval of each request.
    static let defaultTimeoutInterval: TimeInterval = 10

    /// REST client shared instance.
    static let sharedInstance = RESTClient()

    /// User agent of SDK.
    static let userAgent = "LeanCloud-Swift-SDK/\(Version)"

    /// Signature of each request.
    static var signature: String {
        let timestamp = String(format: "%.0f", 1000 * Date().timeIntervalSince1970)
        let hash = "\(timestamp)\(Configuration.sharedInstance.applicationKey!)".MD5String.lowercased()

        return "\(hash),\(timestamp)"
    }

    /// Common REST request headers.
    static var commonHeaders: [String: String] {
        var headers: [String: String] = [
            HeaderFieldName.id:        Configuration.sharedInstance.applicationID,
            HeaderFieldName.signature: self.signature,
            HeaderFieldName.userAgent: self.userAgent,
            HeaderFieldName.accept:    "application/json"
        ]

        if let sessionToken = LCUser.current?.sessionToken {
            headers[HeaderFieldName.session] = sessionToken.value
        }

        return headers
    }

    /// REST host for current service region.
    static var host: String {
        switch Configuration.sharedInstance.serviceRegion {
        case .cn: return "api.leancloud.cn"
        case .us: return "us-api.leancloud.cn"
        }
    }

    /**
     Get endpoint of object.

     - parameter object: The object from which you want to get the endpoint.

     - returns: The endpoint of object.
     */
    static func endpoint(_ object: LCObject) -> String {
        return endpoint(object.actualClassName)
    }

    /**
     Get eigen endpoint of object.

     - parameter object: The object from which you want to get the eigen endpoint.

     - returns: The eigen endpoint of object.
     */
    static func eigenEndpoint(_ object: LCObject) -> String? {
        guard let objectId = object.objectId else {
            return nil
        }

        return "\(endpoint(object))/\(objectId.value)"
    }

    /**
     Get endpoint for class name.

     - parameter className: The class name.

     - returns: The endpoint for class name.
     */
    static func endpoint(_ className: String) -> String {
        switch className {
        case LCUser.objectClassName():
            return "users"
        case LCRole.objectClassName():
            return "roles"
        default:
            return "classes/\(className)"
        }
    }

    /**
     Get absolute REST API URL string for endpoint.

     - parameter endpoint: The REST API endpoint.

     - returns: An absolute REST API URL string.
     */
    static func absoluteURLString(_ endpoint: String) -> String {
        return "https://\(self.host)/\(self.apiVersion)/\(endpoint)"
    }

    /**
     Merge headers with common headers.

     Field in `headers` will overrides the field in common header with the same name.

     - parameter headers: The headers to be merged.

     - returns: The merged headers.
     */
    static func mergeCommonHeaders(_ headers: [String: String]?) -> [String: String] {
        var result = commonHeaders

        headers?.forEach { (key, value) in result[key] = value }

        return result
    }

    /**
     Creates a request to REST API and sends it synchronously.

     - parameter method:     The HTTP Method.
     - parameter endpoint:   The REST API endpoint.
     - parameter parameters: The request parameters.
     - parameter headers:    The request headers.

     - returns: A response object.
     */
    static func request(
        _ method: Method,
        _ endpoint: String,
        headers: [String: String]? = nil,
        parameters: [String: AnyObject]? = nil)
        -> LCResponse
    {
        var result: LCResponse!
        let urlString = absoluteURLString(endpoint)
        let headers   = mergeCommonHeaders(headers)
        var encoding: Akara.ParameterEncoding!

        switch method {
        case .get: encoding = .urlEncodedInURL
        default:   encoding = .json
        }

        let request = Akara.Request(url: URL(string: urlString)!)

        request.method  = method.rawValue
        request.headers = headers

        if let parameters = parameters {
            let anyValue = parameters.mapValue { downcast(object: $0) }
            request.addParameters(anyValue, encoding: encoding)
        }

        let akaraResult = Akara.perform(request)

        switch akaraResult {
        case .success(let response):
            let data = response.body.data(using: String.Encoding.utf8)!
            let value = try! JSONSerialization.jsonObject(with: data, options: [])
            result = LCResponse(value)
        case .failure(let error):
            result = LCResponse(LCError(code: error.code, reason: error.message))
        }

        return result
    }
}
