//
//  RESTClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class RESTClient {
    
    let baseURL: String
    let httpClient: HTTPClient
    
    // MARK: - Requests management
    
    func get(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .URL, completionHandler: HTTPClient.Task.CompletionHandler) -> HTTPClientDataTask {
        return httpClient.get(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func post(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .JSON, completionHandler: HTTPClient.Task.CompletionHandler) -> HTTPClientDataTask {
        return httpClient.post(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func head(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .URL, completionHandler: HTTPClient.Task.CompletionHandler) -> HTTPClientDataTask {
        return httpClient.head(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func delete(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .URL, completionHandler: HTTPClient.Task.CompletionHandler) -> HTTPClientDataTask {
        return httpClient.delete(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func put(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .JSON, completionHandler: HTTPClient.Task.CompletionHandler) -> HTTPClientDataTask {
        return httpClient.put(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func cancelAllTasks() {
        httpClient.cancelAllTasks()
    }
    
    // MARK: - Utils
    
    private func baseURLWithPath(path: String) -> String {
        return (baseURL as NSString).stringByAppendingPathComponent(path)
    }
    
    // MARK: - Initialization
    
    init(baseURL: String, delegateQueue: NSOperationQueue) {
        self.baseURL = baseURL
        self.httpClient = HTTPClient(delegateQueue: delegateQueue)
    }
    
    deinit {
        cancelAllTasks()
    }
    
}