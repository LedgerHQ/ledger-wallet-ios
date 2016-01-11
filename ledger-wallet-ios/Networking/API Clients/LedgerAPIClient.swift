//
//  LedgerAPIClient.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/07/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

private enum LedgerAPIClientHeaderFields: String {
    
    case Platform = "X-Ledger-Platform"
    case Environment = "X-Ledger-Environment"
    case Locale = "X-Ledger-Locale"

}

class LedgerAPIClient: NSObject {
    
    let delegateQueue: NSOperationQueue
    let httpClient: HTTPClient
    let servicesProvider: ServicesProviderType
    
    // MARK: Public methods
    
    func cancelAllTasks() {
        httpClient.cancelAllTasks()
    }
    
    // MARK: Initialization
    
    init(servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        self.servicesProvider = servicesProvider
        
        let workingQueue = NSOperationQueue(name: self.dynamicType.className(), maxConcurrentOperationCount: NSOperationQueueDefaultMaxConcurrentOperationCount)
        self.httpClient = HTTPClient(delegateQueue: workingQueue)
        self.httpClient.additionalHeaders = [
            LedgerAPIClientHeaderFields.Platform.rawValue: "ios",
            LedgerAPIClientHeaderFields.Locale.rawValue: NSLocale.currentLocale().localeIdentifier
        ]
        #if DEBUG
            self.httpClient.additionalHeaders![LedgerAPIClientHeaderFields.Environment.rawValue] = "dev"
        #else
            self.httpClient.additionalHeaders![LedgerAPIClientHeaderFields.Environment.rawValue] = "prod"
        #endif
    }
    
}