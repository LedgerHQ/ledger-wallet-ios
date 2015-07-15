//
//  BaseRestClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class BaseRestClient: SharableObject {
    
    var baseURL: String {
        if _baseURL == nil { _baseURL = preferredBaseURL() }
        return _baseURL
    }
    var httpClient: HTTPClient {
        if _httpClient == nil { _httpClient = HTTPClient() }
        return _httpClient
    }
    var preferences: Preferences {
        if (_preferences == nil) { _preferences = Preferences(storeName: self.className()) }
        return _preferences
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
}