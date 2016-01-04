//
//  WalletAddressCache.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletAddressCache {
    
    private let storeProxy: WalletStoreProxy
    private let workingQueue = NSOperationQueue(name: "WalletAddressCache", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletAddressCache")
    
    // MARK: Addresses management

    func fetchOrDeriveAddressesAtPaths(paths: [WalletAddressPath], queue: NSOperationQueue, completion: ([WalletAddress]?) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
        
            strongSelf.storeProxy.fetchAddressesAtPaths(paths, queue: strongSelf.workingQueue) { [weak self] addresses in
                guard let strongSelf = self else { return }
                
                // check that we found some addresses
                guard let addresses = addresses else {
                    strongSelf.logger.error("Unable to fetch first addresses for given paths")
                    queue.addOperationWithBlock() { completion(nil) }
                    return
                }
                
                // check that we have all the addresses
                guard addresses.count == paths.count else {
                    let fetchedPaths = addresses.map({ $0.path })
                    strongSelf.fetchAccountsForAddressesAtPaths(fetchedPaths, requestedPaths: paths, existingAddresses: addresses, queue: queue, completion: completion)
                    return
                }
                
                queue.addOperationWithBlock() { completion(addresses) }
            }
        }
    }
    
    func fetchAddressesWithAddresses(addresses: [String], queue: NSOperationQueue, completion: ([WalletAddress]?) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.storeProxy.fetchAddressesWithAddresses(addresses, queue: strongSelf.workingQueue) { [weak self] addresses in
                guard let strongSelf = self else { return }
                
                // check that we found some addresses
                guard let addresses = addresses else {
                    strongSelf.logger.error("Unable to fetch addresses for given addresses")
                    queue.addOperationWithBlock() { completion(nil) }
                    return
                }
                
                queue.addOperationWithBlock() { completion(addresses) }
            }
        }
    }
    
    // MARK: Internal methods
    
    private func fetchAccountsForAddressesAtPaths(paths: [WalletAddressPath], requestedPaths: [WalletAddressPath], existingAddresses: [WalletAddress], queue: NSOperationQueue, completion: ([WalletAddress]?) -> Void) {
        // get missing paths
        let missingPaths = requestedPaths.filter({ !paths.contains($0) })
        guard missingPaths.count + existingAddresses.count == requestedPaths.count else {
            logger.error("Unable to compute missing paths to derive addresses")
            queue.addOperationWithBlock() { completion(nil) }
            return
        }
        
        // get unique accounts to fetch
        let uniqueAccounts = uniqueAccountsForPaths(missingPaths)
        guard uniqueAccounts.count > 0 else {
            logger.error("Unable to compute unique accounts to derive addresses")
            queue.addOperationWithBlock() { completion(nil) }
            return
        }
        
        // fetch accounts
        storeProxy.fetchAccountsAtIndexes(uniqueAccounts, queue: workingQueue) { [weak self] accounts in
            guard let strongSelf = self else { return }
            
            guard let accounts = accounts else {
                strongSelf.logger.error("Unable to fetch accounts to derive addresses")
                queue.addOperationWithBlock() { completion(nil) }
                return
            }
            
            // check that we have all the accounts
            guard accounts.count == uniqueAccounts.count else {
                strongSelf.logger.warn("Unable to fetch accounts with indexes \(uniqueAccounts)")
                queue.addOperationWithBlock() { completion(nil) }
                return
            }
            
            strongSelf.deriveAddressesAtPaths(missingPaths, accounts: accounts, existingAddresses: existingAddresses, queue: queue, completion: completion)
        }
    }
    
    private func deriveAddressesAtPaths(paths: [WalletAddressPath], accounts: [WalletAccount], existingAddresses: [WalletAddress], queue: NSOperationQueue, completion: ([WalletAddress]?) -> Void) {
        var addressesCache: [WalletAddress] = []
        var keychainCache: [Int: BTCKeychain] = [:]
        
        // derive all addresses
        for path in paths {
            let deriver: (BTCKeychain, WalletAddressPath) -> Void = { keychain, path in
                guard let key = keychain.keyWithPath(path.chainPath), let address = key.address else {
                    self.logger.error("Unable to derive address for account at index \(path.accountIndex)")
                    queue.addOperationWithBlock() { completion(nil) }
                    return
                }
                
                addressesCache.append(WalletAddress(address: address.string, path: path))
            }
            
            // try to get keychain from account number
            if let keychain = keychainCache[path.accountIndex] {
                deriver(keychain, path)
            }
            else {
                // get account
                guard let account = accountAtIndex(path.accountIndex, accounts: accounts) else {
                    logger.error("Unable to get account at index \(path.accountIndex)")
                    queue.addOperationWithBlock() { completion(nil) }
                    return
                }
                
                // create addresses from xpub
                guard let keychain = BTCKeychain(extendedKey: account.extendedPublicKey) else {
                    logger.error("Unable to create keychain for account at index \(path.accountIndex)")
                    queue.addOperationWithBlock() { completion(nil) }
                    return
                }
                keychainCache[path.accountIndex] = keychain
                deriver(keychain, path)
            }
        }
        
        // save addresses
        storeProxy.addAddresses(addressesCache)

        queue.addOperationWithBlock() { completion(existingAddresses + addressesCache) }
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
    
    private func accountAtIndex(index: Int, accounts: [WalletAccount]) -> WalletAccount? {
        return accounts.filter({ $0.index == index }).first
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy) {
        self.storeProxy = storeProxy
    }
    
}