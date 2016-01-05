//
//  WalletTransactionsStreamSpentFunnel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 17/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsStreamSpentFunnel: WalletTransactionsStreamFunnelType {
    
    private let storeProxy: WalletStoreProxy
    private let callingQueue: NSOperationQueue
    private let logger = Logger.sharedInstance(name: "WalletTransactionsStreamSpentFunnel")
    
    func process(context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        if context.remoteTransaction.transaction.isConfirmed {
            // resolve conflicting transactions
            resolveConflictingTransactions(context, completion: completion)
        }
        else {
            // look for conflicting transactions
            checkForConflictingTransactions(context, completion: completion)
        }
    }

    private func checkForConflictingTransactions(context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        storeProxy.fetchDoubleSpendTransactionsFromTransaction(context.remoteTransaction, queue: callingQueue) { [weak self] transactions in
            guard let strongSelf = self else { return }
            
            // if we managed to fetch transactions
            guard let transactions = transactions else {
                strongSelf.logger.error("Unable to fetch double spent transactions for transaction \(context.remoteTransaction.transaction.hash), continuing")
                completion(true)
                return
            }
            
            // process conflicting transactions
            strongSelf.checkToDiscardTransactionBasedOnConflictingTransactions(transactions, context: context, completion: completion)
        }
    }
    
    private func checkToDiscardTransactionBasedOnConflictingTransactions(transactions: [WalletTransaction], context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        guard transactions.count > 0 else {
            // no transaction is conflicting, continue
            completion(true)
            return
        }
        
        guard !oneTransactionIsAtLeastConfirmed(transactions) else {
            // if at least one transaction is confirmed, discard transaction
            logger.warn("Transaction \(context.remoteTransaction.transaction.hash) conflicts with \(transactions.count) transactions but one is already confirmed, discarding")
            completion(false)
            return
        }
        
        
    }
    
    private func resolveConflictingTransactions(context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        
    }
    
    private func oneTransactionIsAtLeastConfirmed(transactions: [WalletTransaction]) -> Bool {
        return transactions.contains({ $0.isConfirmed })
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy, addressCache: WalletAddressCache, layoutHolder: WalletLayoutHolder, callingQueue: NSOperationQueue) {
        self.storeProxy = storeProxy
        self.callingQueue = callingQueue
    }
    
}