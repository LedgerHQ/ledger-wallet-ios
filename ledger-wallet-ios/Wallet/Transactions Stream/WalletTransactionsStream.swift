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
    private var busy = false
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
    
    // MARK: Internal methods
    
    private func processNextPendingTransaction() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            guard !strongSelf.busy else {
                return
            }
            
            // mark busy
            strongSelf.busy = true
            
            // pop first transaction
            guard let transaction = strongSelf.pendingTransactions.first else {
                strongSelf.busy = false
                return
            }
            strongSelf.pendingTransactions.removeFirst()
            
            // check if we need to discard the transaction
            strongSelf.checkIfTransactionShouldBeDiscarded(transaction)
        }
    }

    private func checkIfTransactionShouldBeDiscarded(transaction: WalletRemoteTransaction) {
        
    }

    private func processTransaction(transaction: WalletRemoteTransaction) {
        
    }
    
    // MARK: Utils
    
    private func allAdressesInTransaction(transaction: WalletRemoteTransaction) -> [String] {
        return []
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