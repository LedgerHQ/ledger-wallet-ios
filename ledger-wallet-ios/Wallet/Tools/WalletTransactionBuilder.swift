//
//  WalletTransactionBuilder.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 23/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionBuilder {
    
    private let storeProxy: WalletStoreProxy
    private let workingQueue = NSOperationQueue(name: "WalletTransactionBuilder", maxConcurrentOperationCount: 1)
    private let delegateQueue: NSOperationQueue
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy, delegateQueue: NSOperationQueue) {
        self.storeProxy = storeProxy
        self.delegateQueue = delegateQueue
    }
    
}