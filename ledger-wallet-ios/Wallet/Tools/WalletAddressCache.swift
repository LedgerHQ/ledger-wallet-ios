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
        
            guard strongSelf.pathsConformBIP32(paths) else {
                strongSelf.logger.error("Unable to fetch addresses at paths that are not conform to BIP32")
                queue.addOperationWithBlock() { completion(nil) }
                return
            }
            
            strongSelf.storeProxy.fetchAddressesAtPaths(paths, completionQueue: strongSelf.workingQueue) { [weak self] addresses in
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

            strongSelf.storeProxy.fetchAddressesWithAddresses(addresses, completionQueue: strongSelf.workingQueue) { [weak self] addresses in
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
    
    private func pathsConformBIP32(paths: [WalletAddressPath]) -> Bool {
        return paths.reduce(true, combine: { $0 && $1.conformsToBIP32 })
    }
    
    private func fetchAccountsForAddressesAtPaths(paths: [WalletAddressPath], requestedPaths: [WalletAddressPath], existingAddresses: [WalletAddress], queue: NSOperationQueue, completion: ([WalletAddress]?) -> Void) {
        // get missing paths
        let missingPaths = requestedPaths.filter({ !paths.contains($0) })
        guard missingPaths.count + existingAddresses.count == requestedPaths.count else {
            logger.error("Unable to compute missing paths to derive addresses")
            queue.addOperationWithBlock() { completion(nil) }
            return
        }
        
        // get unique accounts to fetch
        let uniqueAccountIndexes = uniqueAccountIndexesForPaths(missingPaths)
        guard uniqueAccountIndexes.count > 0 else {
            logger.error("Unable to compute unique account indexes to derive addresses")
            queue.addOperationWithBlock() { completion(nil) }
            return
        }
        
        // fetch accounts
        storeProxy.fetchAccountsAtIndexes(uniqueAccountIndexes, completionQueue: workingQueue) { [weak self] accounts in
            guard let strongSelf = self else { return }
            
            guard let accounts = accounts else {
                strongSelf.logger.error("Unable to fetch accounts to derive addresses")
                queue.addOperationWithBlock() { completion(nil) }
                return
            }
            
            // check that we have all the accounts
            guard accounts.count == uniqueAccountIndexes.count else {
                strongSelf.logger.warn("Unable to fetch accounts with indexes \(uniqueAccountIndexes)")
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
                guard let
                    chainPath = path.pathDroppingFirst(1),
                    key = keychain.keyWithPath(chainPath.representativeString()),
                    address = key.compressedPublicKeyAddress
                else {
                    self.logger.error("Unable to derive address for account at index \(path.BIP32AccountIndex!)")
                    queue.addOperationWithBlock() { completion(nil) }
                    return
                }
                
                addressesCache.append(WalletAddress(address: address.string, path: path, relativePath: path.representativeString()))
            }
            
            // try to get keychain from account number
            if let keychain = keychainCache[path.BIP32AccountIndex!] {
                deriver(keychain, path)
            }
            else {
                // get account
                guard let account = accountAtIndex(path.BIP32AccountIndex!, accounts: accounts) else {
                    logger.error("Unable to get account at index \(path.BIP32AccountIndex!)")
                    queue.addOperationWithBlock() { completion(nil) }
                    return
                }
                
                // create addresses from xpub
                guard let keychain = BTCKeychain(extendedKey: account.extendedPublicKey) else {
                    logger.error("Unable to create keychain for account at index \(path.BIP32AccountIndex!)")
                    queue.addOperationWithBlock() { completion(nil) }
                    return
                }
                keychainCache[path.BIP32AccountIndex!] = keychain
                deriver(keychain, path)
            }
        }
        
        // save addresses
        writeAddresses(addressesCache, existingAddresses: existingAddresses, queue: queue, completion: completion)
    }
    
    private func writeAddresses(addresses: [WalletAddress], existingAddresses: [WalletAddress], queue: NSOperationQueue, completion: ([WalletAddress]?) -> Void) {
        // store newly created adresses
        storeProxy.addAddresses(addresses, completionQueue: workingQueue) { success in
            queue.addOperationWithBlock() {
                if success {
                    completion(existingAddresses + addresses)
                }
                else {
                    completion(nil)
                }
            }
        }
    }
    
    private func uniqueAccountIndexesForPaths(paths: [WalletAddressPath]) -> [Int] {
        var accountIndexes: [Int] = []
        
        paths.forEach { path in
            if !accountIndexes.contains(path.BIP32AccountIndex!) {
                accountIndexes.append(path.BIP32AccountIndex!)
            }
        }
        return accountIndexes
    }
    
    private func accountAtIndex(index: Int, accounts: [WalletAccount]) -> WalletAccount? {
        return accounts.filter({ $0.index == index }).first
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy) {
        self.storeProxy = storeProxy
    }
    
}