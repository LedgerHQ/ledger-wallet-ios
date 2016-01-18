//
//  WalletStoreProxy.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletStoreProxy {
    
    private let store: SQLiteStore
    private let logger = Logger.sharedInstance(name: "WalletStoreProxy")
    
    // MARK: Accounts management
    
    func fetchAllAccounts(completionQueue: NSOperationQueue, completion: ([WalletAccount]?) -> Void) {
        executeModelCollectionFetch({ return WalletStoreExecutor.fetchAllAccounts($0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func fetchAccountAtIndex(index: Int, completionQueue: NSOperationQueue, completion: (WalletAccount?) -> Void) {
        executeModelFetch({ return WalletStoreExecutor.fetchAccountAtIndex(index, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func fetchAccountsAtIndexes(indexes: [Int], completionQueue: NSOperationQueue, completion: ([WalletAccount]?) -> Void) {
        executeModelCollectionFetch({ return WalletStoreExecutor.fetchAccountsAtIndexes(indexes, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func fetchAllVisibleAccountsFrom(from: Int, size: Int, order: WalletFetchRequestOrder, completionQueue: NSOperationQueue, completion: ([WalletAccount]?) -> Void) {
        executeModelCollectionFetch({ return WalletStoreExecutor.fetchAllVisibleAccountsFrom(from, size: size, order: order, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func countAllVisibleAccounts(completionQueue: NSOperationQueue, completion: (Int?) -> Void) {
        executeModelCollectionCount({ return WalletStoreExecutor.countAllVisibleAccounts($0) }, completionQueue: completionQueue, completion: completion)
    }

    func addAccount(account: WalletAccount, completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.addAccount(account, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func setNextExternalIndex(index: Int, forAccountAtIndex accountIndex: Int, completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.setNextIndex(index, forAccountAtIndex: accountIndex, external: true, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func setNextInternalIndex(index: Int, forAccountAtIndex accountIndex: Int, completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.setNextIndex(index, forAccountAtIndex: accountIndex, external: false, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    // MARK: Addresses management
    
    func fetchAddressesAtPaths(paths: [WalletAddressPath], completionQueue: NSOperationQueue, completion: ([WalletAddress]?) -> Void) {
        executeModelCollectionFetch({ return WalletStoreExecutor.fetchAddressesAtPaths(paths, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func fetchAddressesWithAddresses(addresses: [String], completionQueue: NSOperationQueue, completion: ([WalletAddress]?) -> Void) {
        executeModelCollectionFetch({ return WalletStoreExecutor.fetchAddressesWithAddresses(addresses, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func addAddresses(addresses: [WalletAddress], completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.addAddresses(addresses, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    // MARK: Transactions management
    
    func storeTransactions(transactions: [WalletTransactionContainer], completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.storeTransactions(transactions, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func fetchTransactionsConflictingWithTransaction(transaction: WalletTransactionContainer, completionQueue: NSOperationQueue, completion: ([WalletTransaction]?) -> Void) {
        executeModelCollectionFetch({ return WalletStoreExecutor.fetchTransactionsDoubleSpendingWithTransaction(transaction, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func fetchTransactionsToResolveFromConflictsOfTransaction(transaction: WalletTransaction, completionQueue: NSOperationQueue, completion: ([WalletTransaction]?) -> Void) {
        executeModelCollectionFetch({ return WalletStoreExecutor.fetchTransactionsToResolveFromConflictsOfTransaction(transaction, context: $0) }, completionQueue: completionQueue, completion: completion)
    }

    func removeTransactions(transactions: [WalletTransaction], completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.removeTransactions(transactions, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    // MARK: Operations management
    
    func storeOperations(operations: [WalletOperation], completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.storeOperations(operations, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    // MARK: Balances management
    
    func updateBalanceOfAccounts(accounts: [WalletAccount], completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.updateBalanceOfAccounts(accounts, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    // MARK: Double spend conflicts management
    
    func addDoubleSpendConflicts(conflicts: [WalletDoubleSpendConflict], completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.addDoubleSpendConflicts(conflicts, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    // MARK: Internal methods
    
    private func executeModelFetch<T: SQLiteFetchableModel>(block: (SQLiteStoreContext) -> T?, completionQueue: NSOperationQueue, completion: (T?) -> Void) {
        store.performBlock() { [weak self] context in
            guard let _ = self else { return }
            let result = block(context)
            completionQueue.addOperationWithBlock() { completion(result) }
        }
    }
    
    private func executeModelCollectionFetch<T: SQLiteFetchableModel>(block: (SQLiteStoreContext) -> [T]?, completionQueue: NSOperationQueue, completion: ([T]?) -> Void) {
        store.performBlock() { [weak self] context in
            guard let _ = self else { return }
            let results = block(context)
            completionQueue.addOperationWithBlock() { completion(results) }
        }
    }
    
    private func executeModelCollectionCount(block: (SQLiteStoreContext) -> Int?, completionQueue: NSOperationQueue, completion: (Int?) -> Void) {
        store.performBlock() { [weak self] context in
            guard let _ = self else { return }
            let count = block(context)
            completionQueue.addOperationWithBlock() { completion(count) }
        }
    }
    
    private func executeTransaction(block: (SQLiteStoreContext) -> Bool, completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        store.performTransaction() { [weak self] context in
            guard let _ = self else { return false }
            let success = block(context)
            completionQueue.addOperationWithBlock() { completion(success) }
            return success
        }
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore) {
        self.store = store
    }
    
}