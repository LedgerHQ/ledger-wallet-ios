//
//  BaseRestClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class BaseRestClient: BaseManager {
    
    private let baseURL = LedgerAPIBaseURL
    lazy private var httpClient = HTTPClient()
    
    private enum HeaderFields: String {
        case Platform = "X-Ledger-Platform"
        case Environment = "X-Ledger-Environment"
        case Locale = "X-Ledger-Locale"
    }
    
    // MARK: - Requests management
    
    func get(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .URL, completionHandler: HTTPClient.Task.CompletionHandler?) -> HTTPClient.DataTask {
        return httpClient.get(baseURLWithPath(path), completionHandler: completionHandler, parameters: parameters, encoding: encoding)
    }
    
    func post(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .JSON, completionHandler: HTTPClient.Task.CompletionHandler?) -> HTTPClient.DataTask {
        return httpClient.post(baseURLWithPath(path), completionHandler: completionHandler, parameters: parameters, encoding: encoding)
    }
    
    func head(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .URL, completionHandler: HTTPClient.Task.CompletionHandler?) -> HTTPClient.DataTask {
        return httpClient.head(baseURLWithPath(path), completionHandler: completionHandler, parameters: parameters, encoding: encoding)
    }
    
    func delete(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .URL, completionHandler: HTTPClient.Task.CompletionHandler?) -> HTTPClient.DataTask {
        return httpClient.delete(baseURLWithPath(path), completionHandler: completionHandler, parameters: parameters, encoding: encoding)
    }
    
    func put(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .JSON, completionHandler: HTTPClient.Task.CompletionHandler?) -> HTTPClient.DataTask {
        return httpClient.put(baseURLWithPath(path), completionHandler: completionHandler, parameters: parameters, encoding: encoding)
    }
    
    // MARK - URL management
    
    private func baseURLWithPath(path: String) -> String {
        return baseURL.stringByAppendingPathComponent(path)
    }
    
    // MARK: - Initialization
    
    required init() {
        super.init()
        
        httpClient.additionalHeaders = [
            HeaderFields.Platform.rawValue: "ios",
            HeaderFields.Environment.rawValue: inDebugMode() ? "dev" : "prod",
            HeaderFields.Locale.rawValue: NSLocale.currentLocale().localeIdentifier
        ]
    }
    
}