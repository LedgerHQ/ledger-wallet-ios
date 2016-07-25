//
//  HTTPClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

typealias HTTPClientDataTask = NSURLSessionDataTask

final class HTTPClient {
    
    var additionalHeaders: [String: String]?
    var timeoutInterval: NSTimeInterval {
        get { return session.configuration.timeoutIntervalForRequest }
        set { session.configuration.timeoutIntervalForRequest = newValue }
    }
    private let session: NSURLSession
    private let logger = Logger.sharedInstance(name: "HTTPClient")
    private var activeTasksCount = 0
    
    // MARK: Tasks management
    
    func get(URL: NSURL, parameters: Task.Parameters? = nil, encoding: Task.Encoding = .URL, completionHandler: Task.CompletionHandler) -> HTTPClientDataTask {
        return performDataRequest(.GET, URL: URL, parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func post(URL: NSURL, parameters: Task.Parameters? = nil, encoding: Task.Encoding = .JSON, completionHandler: Task.CompletionHandler) -> HTTPClientDataTask {
        return performDataRequest(.POST, URL: URL, parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func delete(URL: NSURL, parameters: Task.Parameters? = nil, encoding: Task.Encoding = .URL, completionHandler: Task.CompletionHandler) -> HTTPClientDataTask {
        return performDataRequest(.DELETE, URL: URL, parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func head(URL: NSURL, parameters: Task.Parameters? = nil, encoding: Task.Encoding = .URL, completionHandler: Task.CompletionHandler) -> HTTPClientDataTask {
        return performDataRequest(.HEAD, URL: URL, parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func put(URL: NSURL, parameters: Task.Parameters? = nil, encoding: Task.Encoding = .JSON, completionHandler: Task.CompletionHandler) -> HTTPClientDataTask {
        return performDataRequest(.PUT, URL: URL, parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func cancelAllTasks() {
        session.getTasksWithCompletionHandler() { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach({ $0.cancel() })
            uploadTasks.forEach({ $0.cancel() })
            downloadTasks.forEach({ $0.cancel() })
        }
    }
    
    private func performDataRequest(method: Task.Method, URL: NSURL, parameters: Task.Parameters? = nil, encoding: Task.Encoding = .URL, completionHandler: Task.CompletionHandler) -> HTTPClientDataTask {
        // create request
        let request = defaultRequest(method, URL: URL)
        
        // encode parameters
        encoding.encode(request, parameters: parameters)

        // handler block
        let handler: ((NSData?, NSURLResponse?, NSError?) -> Void) = { [weak self] data, response, error in
            guard let strongSelf = self else { return }
            
            strongSelf.activeTasksCount -= 1
            ApplicationManager.sharedInstance.stopNetworkActivity()
            
            guard error == nil else {
                if error!.code != NSURLErrorCancelled {
                    strongSelf.postprocessResponse(nil, request: request, error: error)
                    completionHandler(nil, request, nil, error)
                }
                return
            }
            guard let httpResponse = response as? NSHTTPURLResponse else {
                let error = NSError(domain: "HTTPClient", code: NSURLError.BadServerResponse.rawValue, userInfo: nil)
                strongSelf.postprocessResponse(nil, request: request, error: error)
                completionHandler(nil, request, nil, error)
                return
            }
            let statusCode = httpResponse.statusCode
            guard statusCode < 400 else {
                let error = NSError(domain: "HTTPClient", code: NSURLError.BadServerResponse.rawValue, userInfo: nil)
                strongSelf.postprocessResponse(httpResponse, request: request, error: error)
                completionHandler(nil, request, httpResponse, error)
                return
            }
            strongSelf.postprocessResponse(httpResponse, request: request, error: error)
            completionHandler(data, request, httpResponse, nil)
        }
        
        // launch request
        let task = session.dataTaskWithRequest(request, completionHandler: handler)
        preprocessRequest(request)
        task.resume()
        
        activeTasksCount += 1
        ApplicationManager.sharedInstance.startNetworkActivity()
        
        return task
    }
    
    // MARK: Utilities
    
    private func preprocessRequest(request: NSURLRequest) {
        logger.info("-> \(request.HTTPMethod!) \(request.URL!.absoluteString)")
    }
    
    private func postprocessResponse(response: NSHTTPURLResponse?, request: NSURLRequest, error: NSError?) {
        let statusCode = response?.statusCode ?? 0
        if let error = error {
            logger.error("<- \(statusCode) \(request.HTTPMethod!) \(request.URL!.absoluteString) | \(error.localizedDescription)")
        }
        else {
            logger.info("<- \(statusCode) \(request.HTTPMethod!) \(request.URL!.absoluteString)")
        }
    }
    
    // MARK: Requests
    
    private func defaultRequest(method: Task.Method, URL: NSURL) -> NSMutableURLRequest {
        let request = NSMutableURLRequest()
        request.URL = URL
        request.HTTPMethod = method.rawValue
        request.timeoutInterval = session.configuration.timeoutIntervalForRequest
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        return request
    }
    
    // MARK: Initialization
    
    init(delegateQueue: NSOperationQueue) {
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        configuration.timeoutIntervalForRequest = 60
        self.session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: delegateQueue)
    }
    
    deinit {
        for _ in 0..<activeTasksCount {
            ApplicationManager.sharedInstance.stopNetworkActivity()
        }
        session.invalidateAndCancel()
    }
    
}