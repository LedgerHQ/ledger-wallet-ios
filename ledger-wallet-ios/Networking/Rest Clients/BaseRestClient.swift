//
//  BaseRestClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class BaseRestClient {
    
    var baseURL: String {
        if _baseURL == nil { _baseURL = preferredBaseURL() }
        return _baseURL
    }
    var httpClient: HTTPClient {
        if _httpClient == nil { _httpClient = preferredHttpClient() }
        return _httpClient
    }
    
    private var _baseURL: String! = nil
    private var _httpClient: HTTPClient! = nil
    private var _preferences: Preferences! = nil
    
    // MARK: - URL management
    
    func baseURLWithPath(path: String) -> String {
        return baseURL.stringByAppendingString(path)
    }
    
    func preferredBaseURL() -> String {
        return ""
    }
    
    func preferredHttpClient() -> HTTPClient {
        return HTTPClient()
    }
}