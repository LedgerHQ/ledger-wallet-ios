//
//  HTTPClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class HTTPClient {
    
    var autostartRequests = true
    var timeoutInterval: NSTimeInterval = 30
    var additionalHeaders: [String: String]? = nil
    var session: NSURLSession {
        if _session == nil {
            _session = NSURLSession(configuration: preferredSessionConfiguration(), delegate: preferredSessionDelegate(), delegateQueue: preferredSessionDelegateQueue())
        }
        return _session
    }
    private lazy var logger: Logger = Logger.sharedInstance(name: "HTTPClient")
    private var _session: NSURLSession! = nil
    
    // MARK: - Tasks management
    
    func get(URL: String, parameters: Task.Parameters? = nil, encoding: Task.Encoding = .URL, completionHandler: Task.CompletionHandler) -> DataTask {
        return performDataRequest(.GET, URL: URL, parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func post(URL: String, parameters: Task.Parameters? = nil, encoding: Task.Encoding = .URL, completionHandler: Task.CompletionHandler) -> DataTask {
        return performDataRequest(.POST, URL: URL, parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func delete(URL: String, parameters: Task.Parameters? = nil, encoding: Task.Encoding = .URL, completionHandler: Task.CompletionHandler) -> DataTask {
        return performDataRequest(.DELETE, URL: URL, parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func head(URL: String, parameters: Task.Parameters? = nil, encoding: Task.Encoding = .URL, completionHandler: Task.CompletionHandler) -> DataTask {
        return performDataRequest(.HEAD, URL: URL, parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func put(URL: String, parameters: Task.Parameters? = nil, encoding: Task.Encoding = .URL, completionHandler: Task.CompletionHandler) -> DataTask {
        return performDataRequest(.PUT, URL: URL, parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    private func performDataRequest(method: Task.Method, URL: String, parameters: Task.Parameters? = nil, encoding: Task.Encoding = .URL, completionHandler: Task.CompletionHandler) -> DataTask {
        // create request
        let request = defaultRequest(method, URL: URL)
        
        // encode parameters
        encoding.encode(request, parameters: parameters)
        
        // create data task
        let handler: ((NSData?, NSURLResponse?, NSError?) -> Void) = { [weak self] data, response, error in
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            var finalError = error
            if finalError == nil && statusCode < 200 && statusCode > 299 {
                finalError = NSError(domain: "HTTPClientErrorDomain", code: statusCode, userInfo: nil)
            }
            self?.logResponse(httpResponse, request: request, data: data, error: error)
            completionHandler(data, request, httpResponse, finalError)
        }
        logRequest(request)
        let task = session.dataTaskWithRequest(request, completionHandler: handler)
        
        // launch it if necessary
        if autostartRequests {
            task.resume()
        }
        return task
    }
    
    // MARK: - Log
    
    private func logRequest(request: NSURLRequest) {
        logger.info("-> \(request.HTTPMethod!) \(request.URL!)")
    }
    
    private func logResponse(response: NSHTTPURLResponse?, request: NSURLRequest, data: NSData?, error: NSError?) {
        logger.info("<- \(response!.statusCode) \(request.HTTPMethod!) \(request.URL!)")
    }
    
    // MARK: - Requests
    
    private func defaultRequest(method: Task.Method, URL: String) -> NSMutableURLRequest {
        let request = NSMutableURLRequest()
        request.URL = NSURL(string: URL)
        request.HTTPMethod = method.rawValue
        request.timeoutInterval = timeoutInterval
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        return request
    }
    
    // MARK: - Configuration
    
    private func preferredSessionConfiguration() -> NSURLSessionConfiguration {
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        configuration.timeoutIntervalForRequest = timeoutInterval
        return configuration
    }
    
    private func preferredSessionDelegate() -> NSURLSessionDelegate? {
        return nil
    }
    
    private func preferredSessionDelegateQueue() -> NSOperationQueue? {
        return NSOperationQueue.mainQueue()
    }
    
    // MARK: - Initialization
    
    deinit {
        _session?.finishTasksAndInvalidate()
    }
    
}