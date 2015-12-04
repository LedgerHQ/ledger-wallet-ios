//
//  BaseRestClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

protocol BaseRESTClient {
    
    var baseURL: String { get }
    var httpClient: HTTPClient { get }
    func baseURLWithPath(path: String) -> String
        
}

extension BaseRESTClient {
    
    func baseURLWithPath(path: String) -> String {
        return (baseURL as NSString).stringByAppendingPathComponent(path)
    }
    
}