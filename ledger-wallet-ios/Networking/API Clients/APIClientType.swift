//
//  APIClientType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 11/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol APIClientType {
    
    var httpClient: HTTPClient { get }
    
    func cancelAllTasks()
    
    init(servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue)
    
}

extension APIClientType {
    
    func cancelAllTasks() {
        httpClient.cancelAllTasks()
    }
    
}