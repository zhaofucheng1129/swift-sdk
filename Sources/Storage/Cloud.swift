//
//  Cloud.swift
//  LeanCloud
//
//  Created by zapcannon87 on 2019/7/4.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation

public class LCCloud {
    
    /// call the cloud function synchronously
    ///
    /// - Parameters:
    ///   - application: The application
    ///   - function: The name of the function in the cloud
    ///   - parameters: The parameters of the function
    /// - Returns: The result of the function
    public static func run(
        application: LCApplication = LCApplication.default,
        _ function: String,
        parameters: [String: Any]? = nil)
        -> LCGenericResult<Any>
    {
        return expect { (fullfill) in
            self.run(application: application, function: function, parameters: parameters, completionInBackground: { (result) in
                fullfill(result)
            })
        }
    }
    
    /// call the cloud function asynchronously
    ///
    /// - Parameters:
    ///   - application: The application
    ///   - function: The name of the function in the cloud
    ///   - parameters: The parameters of the function
    ///   - completion: The result of the callback
    /// - Returns: The Request
    @discardableResult
    public static func run(
        application: LCApplication = LCApplication.default,
        _ function: String,
        parameters: [String: Any]? = nil,
        completion: @escaping (LCGenericResult<Any>) -> Void)
        -> LCRequest
    {
        return self.run(application: application, function: function, parameters: parameters, completionInBackground: { (result) in
            mainQueueAsync {
                completion(result)
            }
        })
    }
    
    @discardableResult
    private static func run(
        application: LCApplication,
        function: String,
        parameters: [String: Any]? = nil,
        completionInBackground completion: @escaping (LCGenericResult<Any>) -> Void)
        -> LCRequest
    {
        let httpClient: HTTPClient = application.httpClient
        
        let request = httpClient.request(.post, "functions/\(function)", parameters: parameters) { (response) in
            let result = self.handleCloudResult(application: application, response: response)
            completion(result)
        }
        
        return request
    }
    
    /// call the cloud function by RPC synchronously
    ///
    /// - Parameters:
    ///   - application: The application
    ///   - function: The name of the function in the cloud
    ///   - parameters: The parameters of the function
    /// - Returns: The result of the function
    public static func rpc(
        application: LCApplication = LCApplication.default,
        _ function: String,
        parameters: [String: Any]? = nil)
        -> LCGenericResult<Any>
    {
        return expect { (fullfill) in
            self.rpc(application: application, function: function, parameters: parameters, completionInBackground: { (result) in
                fullfill(result)
            })
        }
    }
    
    /// call the cloud function by RPC asynchronously
    ///
    /// - Parameters:
    ///   - application: The application
    ///   - function: The name of the function in the cloud
    ///   - parameters: The parameters of the function
    ///   - completion: The result of the callback
    /// - Returns: The Request
    @discardableResult
    public static func rpc(
        application: LCApplication = LCApplication.default,
        _ function: String,
        parameters: [String: Any]? = nil,
        completion: @escaping (LCGenericResult<Any>) -> Void)
        -> LCRequest
    {
        return self.run(application: application, function: function, parameters: parameters, completionInBackground: { (result) in
            mainQueueAsync {
                completion(result)
            }
        })
    }
    
    @discardableResult
    private static func rpc(
        application: LCApplication,
        function: String,
        parameters: [String: Any]?,
        completionInBackground completion: @escaping (LCGenericResult<Any>) -> Void)
        -> LCRequest
    {
        let httpClient: HTTPClient = application.httpClient
        
        let request = httpClient.request(.post, "call/\(function)", parameters: parameters) { (response) in
            let result = self.handleCloudResult(application: application, response: response)
            completion(result)
        }
        
        return request
    }
    
    private static func handleCloudResult(application: LCApplication, response: LCResponse) -> LCGenericResult<Any> {
        let cloudResult: LCGenericResult<Any>
        
        if let error: Error = response.error {
            cloudResult = .failure(error: LCError(error: error))
        } else {
            if
                let value = response.value as? [String: Any],
                let result = value["result"]
            {
                do {
                    let object = try ObjectProfiler.shared.object(application: application, jsonValue: result)
                    cloudResult = .success(value: object)
                } catch {
                    cloudResult = .failure(error: LCError(error: error))
                }
            } else {
                let error = LCError(code: .invalidType, reason: "invalid response data type.")
                cloudResult = .failure(error: error)
            }
        }
        
        return cloudResult
    }
    
}
