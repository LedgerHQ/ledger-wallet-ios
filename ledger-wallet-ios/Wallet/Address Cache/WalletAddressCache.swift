//
//  WalletAddressCache.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletAddressCache {
    
    private let delegateQueue: NSOperationQueue
    private let workingQueue = NSOperationQueue(name: "WalletAddressCache", maxConcurrentOperationCount: 1)
    private let storeProxy: WalletStoreProxy
    private let logger = Logger.sharedInstance(name: "WalletAddressCache")
    
    // MARK: Addresses management

    func addressesAtPaths(paths: [WalletAddressPath], completion: ([WalletAddressModel]?) -> Void) {
        storeProxy.fetchAddressesAtPaths(paths) { [weak self] addresses in
            guard let strongSelf = self else { return }
            
            // check that we found some addresses
            guard let addresses = addresses else {
                strongSelf.logger.error("Unable to fetch first addresses for given paths")
                strongSelf.delegateQueue.addOperationWithBlock() { completion(nil) }
                return
            }
            
            // check that we have all the addresses
            guard addresses.count == paths.count else {
                let fetchedPaths = addresses.map({ $0.path })
                strongSelf.fetchAccountsForAddressesAtPaths(fetchedPaths, requestedPaths: paths, existingAddresses: addresses, completion: completion)
                return
            }
            
            strongSelf.delegateQueue.addOperationWithBlock() { completion(addresses) }
        }
    }
    
    func addressesWithAddresses(addresses: [String], completion: ([WalletAddressModel]?) -> Void) {
        storeProxy.fetchAddressesWithAddresses(addresses) { [weak self] addresses in
            guard let strongSelf = self else { return }

            strongSelf.delegateQueue.addOperationWithBlock() { completion(addresses) }
        }
    }
    
    // MARK: Internal methods
    
    private func fetchAccountsForAddressesAtPaths(paths: [WalletAddressPath], requestedPaths: [WalletAddressPath], existingAddresses: [WalletAddressModel], completion: ([WalletAddressModel]?) -> Void) {
        // get missing paths
        let missingPaths = requestedPaths.filter({ !paths.contains($0) })
        guard missingPaths.count + existingAddresses.count == requestedPaths.count else {
            logger.error("Unable to compute missing paths to derive addresses")
            delegateQueue.addOperationWithBlock() { completion(nil) }
            return
        }
        
        // get unique accounts to fetch
        let uniqueAccounts = uniqueAccountsForPaths(missingPaths)
        guard uniqueAccounts.count > 0 else {
            logger.error("Unable to compute unique accounts to derive addresses")
            delegateQueue.addOperationWithBlock() { completion(nil) }
            return
        }
        
        // fetch accounts
        storeProxy.fetchAccountsAtIndexes(uniqueAccounts) { [weak self] accounts in
            guard let strongSelf = self else { return }
            
            guard let accounts = accounts else {
                strongSelf.logger.error("Unable to fetch accounts to derive addresses")
                strongSelf.delegateQueue.addOperationWithBlock() { completion(nil) }
                return
            }
            
            // check that we have all the accounts
            guard accounts.count == uniqueAccounts.count else {
                strongSelf.logger.warn("Unable to fetch accounts with indexes \(uniqueAccounts)")
                strongSelf.delegateQueue.addOperationWithBlock() { completion(nil) }
                return
            }
            
            strongSelf.deriveAddressesAtPaths(missingPaths, accounts: accounts, existingAddresses: existingAddresses, completion: completion)
        }
    }
    
    private func deriveAddressesAtPaths(paths: [WalletAddressPath], accounts: [WalletAccountModel], existingAddresses: [WalletAddressModel], completion: ([WalletAddressModel]?) -> Void) {
        // derive all addresses
        var addressesCache: [WalletAddressModel] = []
        for path in paths {
            // get account
            guard let account = accountAtIndex(path.accountIndex, accounts: accounts) else {
                logger.error("Unable to get account at index \(path.accountIndex)")
                delegateQueue.addOperationWithBlock() { completion(nil) }
                return
            }
            
            // create addresses from xpub
            guard let keychain = BTCKeychain(extendedKey: account.extendedPublicKey) else {
                logger.error("Unable to create keychain for account at index \(path.accountIndex)")
                delegateQueue.addOperationWithBlock() { completion(nil) }
                return
            }

            guard let key = keychain.keyWithPath(path.chainPath), let address = key.address else {
                logger.error("Unable to derive address for account at index \(path.accountIndex)")
                delegateQueue.addOperationWithBlock() { completion(nil) }
                return
            }
            addressesCache.append(WalletAddressModel(address: address.string, path: path))
        }
        
        // save addresses
        storeProxy.storeAddresses(addressesCache)

        delegateQueue.addOperationWithBlock() { completion(existingAddresses + addressesCache) }
    }
    
    private func uniqueAccountsForPaths(paths: [WalletAddressPath]) -> [Int] {
        var uniqueAccounts: [Int] = []
        
        paths.forEach { path in
            if !uniqueAccounts.contains(path.accountIndex) {
                uniqueAccounts.append(path.accountIndex)
            }
        }
        return uniqueAccounts
    }
    
    private func accountAtIndex(index: Int, accounts: [WalletAccountModel]) -> WalletAccountModel? {
        return accounts.filter({ $0.index == index }).first
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore, delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        self.storeProxy = WalletStoreProxy(store: store, delegateQueue: workingQueue)
    }
    
}