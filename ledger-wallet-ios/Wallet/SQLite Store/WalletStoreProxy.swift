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
        executeBlock({ return WalletStoreExecutor.fetchAllAccounts($0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func fetchAccountAtIndex(index: Int, completionQueue: NSOperationQueue, completion: (WalletAccount?) -> Void) {
        executeBlock({ return WalletStoreExecutor.fetchAccountAtIndex(index, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func fetchAccountsAtIndexes(indexes: [Int], completionQueue: NSOperationQueue, completion: ([WalletAccount]?) -> Void) {
        executeBlock({ return WalletStoreExecutor.fetchAccountsAtIndexes(indexes, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func fetchVisibleAccountsFrom(from: Int, size: Int, order: WalletFetchRequestOrder, completionQueue: NSOperationQueue, completion: ([WalletAccount]?) -> Void) {
        executeBlock({ return WalletStoreExecutor.fetchVisibleAccountsFrom(from, size: size, order: order, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func countVisibleAccounts(completionQueue: NSOperationQueue, completion: (Int?) -> Void) {
        executeBlock({ return WalletStoreExecutor.countVisibleAccounts($0) }, completionQueue: completionQueue, completion: completion)
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
        executeBlock({ return WalletStoreExecutor.fetchAddressesAtPaths(paths, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func fetchAddressesWithAddresses(addresses: [String], completionQueue: NSOperationQueue, completion: ([WalletAddress]?) -> Void) {
        executeBlock({ return WalletStoreExecutor.fetchAddressesWithAddresses(addresses, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func addAddresses(addresses: [WalletAddress], completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.addAddresses(addresses, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    // MARK: Transactions management
    
    func storeTransactions(transactions: [WalletTransactionContainer], completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.storeTransactions(transactions, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func fetchTransactionsConflictingWithTransaction(transaction: WalletTransactionContainer, completionQueue: NSOperationQueue, completion: ([WalletTransaction]?) -> Void) {
        executeBlock({ return WalletStoreExecutor.fetchTransactionsDoubleSpendingWithTransaction(transaction, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func fetchTransactionsToResolveFromConflictsOfTransaction(transaction: WalletTransaction, completionQueue: NSOperationQueue, completion: ([WalletTransaction]?) -> Void) {
        executeBlock({ return WalletStoreExecutor.fetchTransactionsToResolveFromConflictsOfTransaction(transaction, context: $0) }, completionQueue: completionQueue, completion: completion)
    }

    func countTransactionsWithHashes(hashes: [String], completionQueue: NSOperationQueue, completion: (Int?) -> Void) {
        executeBlock({ return WalletStoreExecutor.countTransactionsWithHashes(hashes, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func removeTransactions(transactions: [WalletTransaction], completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.removeTransactions(transactions, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    // MARK: Operations management
    
    func storeOperations(operations: [WalletOperation], completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.storeOperations(operations, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    // MARK: Blocks management

    func storeBlocks(blocks: [WalletBlockContainer], completionQueue: NSOperationQueue, completion: (Bool) -> Void) {
        executeTransaction({ return WalletStoreExecutor.storeBlocks(blocks, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    // MARK: Account operation management
    
    func fetchVisibleAccountOperationsForAccountAtIndex(index: Int?, from: Int, size: Int, order: WalletFetchRequestOrder, completionQueue: NSOperationQueue, completion: ([WalletAccountOperationContainer]?) -> Void) {
        executeBlock({ return WalletStoreExecutor.fetchVisibleAccountOperationsForAccountAtIndex(index, from: from, size: size, order: order, context: $0) }, completionQueue: completionQueue, completion: completion)
    }
    
    func countVisibleAccountOperationsForAccountAtIndex(index: Int?, completionQueue: NSOperationQueue, completion: (Int?) -> Void) {
        executeBlock({ return WalletStoreExecutor.countVisibleAccountOperationsForAccountAtIndex(index, context: $0) }, completionQueue: completionQueue, completion: completion)
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
    
    private func executeBlock<T>(block: (SQLiteStoreContext) -> T, completionQueue: NSOperationQueue, completion: (T) -> Void) {
        store.performBlock() { [weak self] context in
            guard let _ = self else { return }
            let result = block(context)
            completionQueue.addOperationWithBlock() { completion(result) }
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