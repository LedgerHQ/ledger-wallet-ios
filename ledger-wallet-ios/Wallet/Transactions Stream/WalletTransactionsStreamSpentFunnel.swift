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
    private let logger = Logger.sharedInstance(name: "WalletTransactionsStreamSpentFunnel")
    
    func process(context: WalletTransactionsStreamContext, workingQueue: NSOperationQueue, completion: (Bool) -> Void) {
        if context.remoteTransaction.transaction.isConfirmed {
            // resolve conflicting transactions
            checkForConflictsToResolve(context, workingQueue: workingQueue, completion: completion)
        }
        else {
            // look for conflicting transactions
            checkIfConflictsCreationIsNecessary(context, workingQueue: workingQueue, completion: completion)
        }
    }

    // MARK: Conflict creation
    
    private func checkIfConflictsCreationIsNecessary(context: WalletTransactionsStreamContext, workingQueue: NSOperationQueue, completion: (Bool) -> Void) {
        storeProxy.fetchTransactionsToResolveFromConflictsOfTransaction(context.remoteTransaction.transaction, queue: workingQueue) { [weak self] transactions in
            guard let strongSelf = self else { return }

            // if we got conflicting transactions
            guard let transactions = transactions else {
                strongSelf.logger.error("Unable to determine if double spend conflict already exist for transaction \(context.remoteTransaction.transaction.hash), continuing")
                completion(true)
                return
            }

            // check if we have existing conflicting transactions
            guard transactions.count == 0 else {
                strongSelf.logger.info("Double spend conflicts already exist for transaction \(context.remoteTransaction.transaction.hash), continuing")
                completion(true)
                return
            }
            
            // we need to check for potential conflicts
            strongSelf.checkForConflictingTransactions(context, workingQueue: workingQueue, completion: completion)
        }
    }
    
    private func checkForConflictingTransactions(context: WalletTransactionsStreamContext, workingQueue: NSOperationQueue, completion: (Bool) -> Void) {
        storeProxy.fetchTransactionsConflictingWithTransaction(context.remoteTransaction, queue: workingQueue) { [weak self] transactions in
            guard let strongSelf = self else { return }
            
            // if we managed to fetch transactions
            guard let transactions = transactions else {
                strongSelf.logger.error("Unable to fetch transactions that conflict with transaction \(context.remoteTransaction.transaction.hash), continuing")
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
            logger.warn("Transaction \(context.remoteTransaction.transaction.hash) conflicts with \(transactions.count) transaction(s) but one of them is already confirmed, discarding")
            completion(false)
            return
        }
        
        // build conflicts
        buildConflictsFromTransactions(transactions, context: context, completion: completion)
    }
    
    private func buildConflictsFromTransactions(transactions: [WalletTransaction], context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        var doubleSpendConflicts: [WalletDoubleSpendConflict] = []
        
        // build transactions conflict pairs
        for transaction in transactions {
            doubleSpendConflicts.append(WalletDoubleSpendConflict(leftTransactionHash: context.remoteTransaction.transaction.hash, rightTransactionHash: transaction.hash))
            doubleSpendConflicts.append(WalletDoubleSpendConflict(leftTransactionHash: transaction.hash, rightTransactionHash: context.remoteTransaction.transaction.hash))
        }
        
        // continue
        logger.info("Storing \(doubleSpendConflicts.count) conflict(s) for transaction \(context.remoteTransaction.transaction.hash)")
        context.conflictsToAdd.appendContentsOf(doubleSpendConflicts)
        completion(true)
    }
    
    private func oneTransactionIsAtLeastConfirmed(transactions: [WalletTransaction]) -> Bool {
        return transactions.contains({ $0.isConfirmed })
    }
    
    // MARK: Conflict resolution
    
    private func checkForConflictsToResolve(context: WalletTransactionsStreamContext, workingQueue: NSOperationQueue, completion: (Bool) -> Void) {
        storeProxy.fetchTransactionsToResolveFromConflictsOfTransaction(context.remoteTransaction.transaction, queue: workingQueue) { [weak self] transactions in
            guard let strongSelf = self else { return }
            
            // if we got conflicting transactions
            guard let transactions = transactions else {
                strongSelf.logger.error("Unable to fetch transactions to resolve from double spend conflicts of transaction \(context.remoteTransaction.transaction.hash), continuing")
                completion(true)
                return
            }
            
            // check if we have existing conflicts
            guard transactions.count > 0 else {
                completion(true)
                return
            }
            
            // resolve conflicts
            strongSelf.resolveConflictsFromTransactions(transactions, context: context, completion: completion)
        }
    }
    
    private func resolveConflictsFromTransactions(transactions: [WalletTransaction], context: WalletTransactionsStreamContext, completion: (Bool) -> Void) {
        logger.info("Resolving \(transactions.count) conflict(s) from transaction \(context.remoteTransaction.transaction.hash)")
        context.transactionsToRemove.appendContentsOf(transactions)
        completion(true)
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy) {
        self.storeProxy = storeProxy
    }
    
}