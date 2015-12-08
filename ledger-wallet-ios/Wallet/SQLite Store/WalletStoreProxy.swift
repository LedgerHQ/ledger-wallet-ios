//
//  WalletStoreProxy.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletStoreProxy {
    
    private let handlersQueue: NSOperationQueue
    private let store: SQLiteStore
    private let logger = Logger.sharedInstance(name: "WalletStoreProxy")
    
    // MARK: - Accounts management
    
    func fetchAccountAtIndex(index: Int, completion: (WalletAccount?) -> Void) {
        executeModelFetch({ WalletStoreExecutor.accountAtIndex(index, context: $0) }, completion: completion)
    }

    // MARK: - Addresses management
    
    func fetchAddressesAtPaths(paths: [WalletAddressPath], completion: ([WalletAddress]?) -> Void) {
        executeModelCollectionFetch({ WalletStoreExecutor.addressesAtPath(paths, context: $0) }, completion: completion)
    }
    
    func addAddresses(addresses: [WalletAddress]) {
        executeModelCollectionInsert({ WalletStoreExecutor.storeAddresses(addresses, context: $0) })
    }
    
    // MARK: - Internal methods
    
    private func executeModelFetch<T: SQLiteFetchableModel>(block: (SQLiteStoreContext) -> T?, completion: (T?) -> Void) {
        store.performBlock() { [weak self] context in
            guard let strongSelf = self else { return }
            let result = block(context)
            strongSelf.handlersQueue.addOperationWithBlock() {
                guard let _ = self else { return }
                completion(result)
            }
        }
    }
    
    private func executeModelCollectionFetch<T: SQLiteFetchableModel>(block: (SQLiteStoreContext) -> [T]?, completion: ([T]?) -> Void) {
        store.performBlock() { [weak self] context in
            guard let strongSelf = self else { return }
            let results = block(context)
            strongSelf.handlersQueue.addOperationWithBlock() {
                guard let _ = self else { return }
                completion(results)
            }
        }
    }
    
    private func executeModelCollectionInsert(block: (SQLiteStoreContext) -> Bool) {
        store.performTransaction() { [weak self] context in
            guard let _ = self else { return false }
            return block(context)
        }
    }
    
    // MARK: - Initialization
    
    init(store: SQLiteStore, handlersQueue: NSOperationQueue) {
        self.store = store
        self.handlersQueue = handlersQueue
    }
    
}