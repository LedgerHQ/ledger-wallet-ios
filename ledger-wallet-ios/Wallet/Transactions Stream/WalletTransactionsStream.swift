//
//  WalletTransactionsStream.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsStream {
    
    private var pendingTransactions: [WalletRemoteTransaction] = []
    private let addressCache: WalletAddressCache
    private let layoutHolder: WalletLayoutHolder
    private let delegateQueue: NSOperationQueue
    private let workingQueue = NSOperationQueue(name: "WalletTransactionsStream", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletTransactionsStream")
    
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
    
    func reloadLayout() {
        layoutHolder.reload()
    }
    
    private func processNextPendingTransaction() {
        // pop first transaction
        guard let transaction = pendingTransactions.first else {
            self.logger.warn("No more pending transactions to process")
            return
        }
        pendingTransactions.removeFirst()
        
        print("handle transation")
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore, delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        self.layoutHolder = WalletLayoutHolder(store: store)
        self.addressCache = WalletAddressCache(store: store, delegateQueue: workingQueue)
    }
    
    deinit {
        discardPendingTransactions()
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
}