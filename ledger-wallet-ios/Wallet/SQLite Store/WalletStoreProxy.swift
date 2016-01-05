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
    
    func fetchAllAccounts(queue: NSOperationQueue, completion: ([WalletAccount]?) -> Void) {
        executeModelCollectionFetch({ return WalletStoreExecutor.fetchAllAccounts($0) }, queue: queue, completion: completion)
    }
    
    func fetchAccountAtIndex(index: Int, queue: NSOperationQueue, completion: (WalletAccount?) -> Void) {
        executeModelFetch({ return WalletStoreExecutor.fetchAccountAtIndex(index, context: $0) }, queue: queue, completion: completion)
    }
    
    func fetchAccountsAtIndexes(indexes: [Int], queue: NSOperationQueue, completion: ([WalletAccount]?) -> Void) {
        executeModelCollectionFetch({ return WalletStoreExecutor.fetchAccountsAtIndexes(indexes, context: $0) }, queue: queue, completion: completion)
    }
    
    func fetchAllVisibleAccounts(queue: NSOperationQueue, completion: ([WalletAccount]?) -> Void) {
        executeModelCollectionFetch({ return WalletStoreExecutor.fetchAllVisibleAccounts($0) }, queue: queue, completion: completion)
    }

    func addAccount(account: WalletAccount) {
        executeTransaction({ return WalletStoreExecutor.addAccount(account, context: $0) })
    }
    
    func setNextExternalIndex(index: Int, forAccountAtIndex accountIndex: Int) {
        executeTransaction({ return WalletStoreExecutor.setNextIndex(index, forAccountAtIndex: accountIndex, external: true, context: $0) })
    }
    
    func setNextInternalIndex(index: Int, forAccountAtIndex accountIndex: Int) {
        executeTransaction({ return WalletStoreExecutor.setNextIndex(index, forAccountAtIndex: accountIndex, external: false, context: $0) })
    }
    
    func updateAllAccountBalances() {
        executeTransaction({ return WalletStoreExecutor.updateAllAccountBalances($0) })
    }
    
    // MARK: Addresses management
    
    func fetchAddressesAtPaths(paths: [WalletAddressPath], queue: NSOperationQueue, completion: ([WalletAddress]?) -> Void) {
        executeModelCollectionFetch({ return WalletStoreExecutor.fetchAddressesAtPaths(paths, context: $0) }, queue: queue, completion: completion)
    }
    
    func fetchAddressesWithAddresses(addresses: [String], queue: NSOperationQueue, completion: ([WalletAddress]?) -> Void) {
        executeModelCollectionFetch({ return WalletStoreExecutor.fetchAddressesWithAddresses(addresses, context: $0) }, queue: queue, completion: completion)
    }
    
    func addAddresses(addresses: [WalletAddress]) {
        executeTransaction({ return WalletStoreExecutor.addAddresses(addresses, context: $0) })
    }
    
    // MARK: Transactions management
    
    func storeTransactions(transactions: [WalletTransactionContainer]) {
        executeTransaction({ return WalletStoreExecutor.storeTransactions(transactions, context: $0) })
    }
    
    func fetchDoubleSpendTransactionsFromTransaction(transaction: WalletTransactionContainer, queue: NSOperationQueue, completion: ([WalletTransaction]?) -> Void) {
        executeModelCollectionFetch({ return WalletStoreExecutor.fetchDoubleSpendTransactionsFromTransaction(transaction, context: $0) }, queue: queue, completion: completion)
    }
    
    // MARK: Operations management
    
    func storeOperations(operations: [WalletOperation]) {
        executeTransaction({ return WalletStoreExecutor.storeOperations(operations, context: $0) })
    }
    
    // MARK: Internal methods
    
    private func executeModelFetch<T: SQLiteFetchableModel>(block: (SQLiteStoreContext) -> T?, queue: NSOperationQueue, completion: (T?) -> Void) {
        store.performBlock() { [weak self] context in
            guard let _ = self else { return }
            let result = block(context)
            queue.addOperationWithBlock() { completion(result) }
        }
    }
    
    private func executeModelCollectionFetch<T: SQLiteFetchableModel>(block: (SQLiteStoreContext) -> [T]?, queue: NSOperationQueue, completion: ([T]?) -> Void) {
        store.performBlock() { [weak self] context in
            guard let _ = self else { return }
            let results = block(context)
            queue.addOperationWithBlock() { completion(results) }
        }
    }
    
    private func executeTransaction(block: (SQLiteStoreContext) -> Bool) {
        store.performTransaction() { [weak self] context in
            guard let _ = self else { return false }
            return block(context)
        }
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore) {
        self.store = store
    }
    
}