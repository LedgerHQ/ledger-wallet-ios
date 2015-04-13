//
//  BaseRestClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class BaseRestClient: SharableObject {
    
    private let baseURL = LedgerAPIBaseURL
    lazy private var httpClient = HTTPClient()

    private enum HeaderFields: String {
        case Platform = "X-Ledger-Platform"
        case Environment = "X-Ledger-Environment"
        case Locale = "X-Ledger-Locale"
    }
    
    // MARK: - Requests management
    
    func get(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .URL, completionHandler: HTTPClient.Task.CompletionHandler?) -> HTTPClient.DataTask {
        return httpClient.get(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func post(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .JSON, completionHandler: HTTPClient.Task.CompletionHandler?) -> HTTPClient.DataTask {
        return httpClient.post(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func head(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .URL, completionHandler: HTTPClient.Task.CompletionHandler?) -> HTTPClient.DataTask {
        return httpClient.head(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func delete(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .URL, completionHandler: HTTPClient.Task.CompletionHandler?) -> HTTPClient.DataTask {
        return httpClient.delete(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func put(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .JSON, completionHandler: HTTPClient.Task.CompletionHandler?) -> HTTPClient.DataTask {
        return httpClient.put(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    // MARK - URL management
    
    private func baseURLWithPath(path: String) -> String {
        return baseURL.stringByAppendingString(path)
    }
    
    // MARK: - Initialization
    
    required init() {
        super.init()
        
        httpClient.additionalHeaders = [
            HeaderFields.Platform.rawValue: "ios",
            HeaderFields.Environment.rawValue: ApplicationManager.sharedInstance().isInDebug ? "dev" : "prod",
            HeaderFields.Locale.rawValue: NSLocale.currentLocale().localeIdentifier
        ]
    }
    
}