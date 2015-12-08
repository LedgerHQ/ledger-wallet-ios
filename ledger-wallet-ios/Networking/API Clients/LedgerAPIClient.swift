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

    let restClient: RESTClient
    let delegateQueue: NSOperationQueue
    
    // MARK: Public methods
    
    func cancelAllTasks() {
        restClient.cancelAllTasks()
    }
    
    // MARK: Initialization
    
    init(delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        
        let workingQueue = NSOperationQueue()
        workingQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
        workingQueue.name = dispatchQueueNameForIdentifier(self.dynamicType.className())
        self.restClient = RESTClient(baseURL: LedgerAPIBaseURL, delegateQueue: workingQueue)
        self.restClient.httpClient.additionalHeaders = [
            LedgerAPIClientHeaderFields.Platform.rawValue: "ios",
            LedgerAPIClientHeaderFields.Locale.rawValue: NSLocale.currentLocale().localeIdentifier
        ]
        #if DEBUG
            self.restClient.httpClient.additionalHeaders![LedgerAPIClientHeaderFields.Environment.rawValue] = "dev"
        #else
            self.restClient.httpClient.additionalHeaders![LedgerAPIClientHeaderFields.Environment.rawValue] = "prod"
        #endif
    }
    
}