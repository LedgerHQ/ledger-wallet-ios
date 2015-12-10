//
//  WalletTransactionsStream.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsStream {
    
    private let storeProxy: WalletStoreProxy
    private var pendingTransactions: [WalletRemoteTransaction] = []
    private let delegateQueue: NSOperationQueue
    private let workingQueue = NSOperationQueue(name: "WalletTransactionsStream", maxConcurrentOperationCount: 1)
    
    // MARK: Transactions management
    
    func enqueueTransactions(transactions: [WalletRemoteTransaction]) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.pendingTransactions.appendContentsOf(transactions)
            strongSelf.processNextPendingTransaction()
        }
    }
    
    func discardPendingTransactions() {
        workingQueue.cancelAllOperations()
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.pendingTransactions = []
        }
    }
    
    private func processNextPendingTransaction() {
        
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore, delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        self.storeProxy = WalletStoreProxy(store: store, delegateQueue: workingQueue)
    }
    
    deinit {
        discardPendingTransactions()
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
}