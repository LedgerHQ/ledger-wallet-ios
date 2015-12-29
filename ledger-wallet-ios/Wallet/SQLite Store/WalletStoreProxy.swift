//
//  WalletStoreProxy.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletStoreProxy {
    
    private let delegateQueue: NSOperationQueue
    private let store: SQLiteStore
    private let logger = Logger.sharedInstance(name: "WalletStoreProxy")
    
    // MARK: Accounts management
    
    func fetchAllAccounts(completion: ([WalletAccountModel]?) -> Void) {
        executeModelCollectionFetch({ WalletStoreExecutor.fetchAllAccounts($0) }, completion: completion)
    }
    
    func fetchAccountAtIndex(index: Int, completion: (WalletAccountModel?) -> Void) {
        executeModelFetch({ WalletStoreExecutor.fetchAccountAtIndex(index, context: $0) }, completion: completion)
    }
    
    func fetchAccountsAtIndexes(indexes: [Int], completion: ([WalletAccountModel]?) -> Void) {
        executeModelCollectionFetch({ WalletStoreExecutor.fetchAccountsAtIndexes(indexes, context: $0) }, completion: completion)
    }

    func addAccount(account: WalletAccountModel) {
        executeTransaction({ return WalletStoreExecutor.addAccount(account, context: $0) })
    }
    
    func setNextExternalIndex(index: Int, forAccountAtIndex accountIndex: Int) {
        executeTransaction({ return WalletStoreExecutor.setNextIndex(index, forAccountAtIndex: accountIndex, external: true, context: $0) })
    }
    
    func setNextInternalIndex(index: Int, forAccountAtIndex accountIndex: Int) {
        executeTransaction({ return WalletStoreExecutor.setNextIndex(index, forAccountAtIndex: accountIndex, external: false, context: $0) })
    }
    
    // MARK: Addresses management
    
    func fetchAddressesAtPaths(paths: [WalletAddressPath], completion: ([WalletAddressModel]?) -> Void) {
        executeModelCollectionFetch({ WalletStoreExecutor.fetchAddressesAtPaths(paths, context: $0) }, completion: completion)
    }
    
    func fetchAddressesWithAddresses(addresses: [String], completion: ([WalletAddressModel]?) -> Void) {
        executeModelCollectionFetch({ WalletStoreExecutor.fetchAddressesWithAddresses(addresses, context: $0) }, completion: completion)
    }
    
    func storeAddresses(addresses: [WalletAddressModel]) {
        executeTransaction({ return WalletStoreExecutor.storeAddresses(addresses, context: $0) })
    }
    
    // MARK: Transactions management
    
    func storeTransactions(transactions: [WalletRemoteTransaction]) {
        executeTransaction({ return WalletStoreExecutor.storeTransactions(transactions, context: $0) })
    }
    
    // MARK: Operations management
    
    func storeOperations(operations: [WalletLocalOperation]) {
        executeTransaction({ return WalletStoreExecutor.storeOperations(operations, context: $0) })
    }
    
    // MARK: Internal methods
    
    private func executeModelFetch<T: SQLiteFetchableModel>(block: (SQLiteStoreContext) -> T?, completion: (T?) -> Void) {
        store.performBlock() { [weak self] context in
            guard let strongSelf = self else { return }
            let result = block(context)
            strongSelf.delegateQueue.addOperationWithBlock() { completion(result) }
        }
    }
    
    private func executeModelCollectionFetch<T: SQLiteFetchableModel>(block: (SQLiteStoreContext) -> [T]?, completion: ([T]?) -> Void) {
        store.performBlock() { [weak self] context in
            guard let strongSelf = self else { return }
            let results = block(context)
            strongSelf.delegateQueue.addOperationWithBlock() { completion(results) }
        }
    }
    
    private func executeTransaction(block: (SQLiteStoreContext) -> Bool) {
        store.performTransaction() { [weak self] context in
            guard let _ = self else { return false }
            return block(context)
        }
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore, delegateQueue: NSOperationQueue) {
        self.store = store
        self.delegateQueue = delegateQueue
    }
    
}