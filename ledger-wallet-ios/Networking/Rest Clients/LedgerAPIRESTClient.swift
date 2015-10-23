//
//  LedgerAPIRESTClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/07/15.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class LedgerAPIRESTClient: BaseRESTClient {
    
    lazy var baseURL = LedgerAPIBaseURL
    lazy var httpClient: HTTPClient = {
        let httpClient = HTTPClient()
        httpClient.additionalHeaders = [
            HeaderFields.Platform.rawValue: "ios",
            HeaderFields.Environment.rawValue: ApplicationManager.sharedInstance.isInDebug ? "dev" : "prod",
            HeaderFields.Locale.rawValue: NSLocale.currentLocale().localeIdentifier
        ]
        return httpClient
    }()
    
    private enum HeaderFields: String {
        case Platform = "X-Ledger-Platform"
        case Environment = "X-Ledger-Environment"
        case Locale = "X-Ledger-Locale"
    }
    
    // MARK: - Requests management
    
    func get(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .URL, completionHandler: HTTPClient.Task.CompletionHandler) -> HTTPClient.DataTask {
        return httpClient.get(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func post(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .JSON, completionHandler: HTTPClient.Task.CompletionHandler) -> HTTPClient.DataTask {
        return httpClient.post(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func head(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .URL, completionHandler: HTTPClient.Task.CompletionHandler) -> HTTPClient.DataTask {
        return httpClient.head(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func delete(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .URL, completionHandler: HTTPClient.Task.CompletionHandler) -> HTTPClient.DataTask {
        return httpClient.delete(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }
    
    func put(path: String, parameters: HTTPClient.Task.Parameters? = nil, encoding: HTTPClient.Task.Encoding = .JSON, completionHandler: HTTPClient.Task.CompletionHandler) -> HTTPClient.DataTask {
        return httpClient.put(baseURLWithPath(path), parameters: parameters, encoding: encoding, completionHandler: completionHandler)
    }

}