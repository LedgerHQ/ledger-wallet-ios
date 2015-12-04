//
//  WalletLayoutDiscoverer.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletLayoutDiscovererDelegate: class {
    
    func layoutDiscoverer(layoutDiscoverer: WalletLayoutDiscoverer, didFinishDiscoveryAtAccountIndex: Int)
    
}

final class WalletLayoutDiscoverer {
    
    weak var delegate: WalletLayoutDiscovererDelegate?
    private var discoveringLayout = false
    private let storeProxy: WalletStoreProxy
    private let restClient = TransactionsRESTClient()
    private let logger = Logger.sharedInstance(name: "WalletLayoutDiscoverer")
    private var currentAccount: WalletDiscoverableAccount!
    private let keyIncrement = 20
    
    // Cette histoire d'account qui traine n'est pas beau, plutot le transformer en xpub (xpub provider?)
    // C'est fouilli, peut-être dédier un objet à la descente d'une batch de 20 adresses et boucler dessus
    
    // MARK: Layout discovery
    
    func startDiscovery() {
        guard !discoveringLayout else {
            return
        }
        discoveringLayout = true
        
        logger.info("Starting discovery")
        fetchExtendedPublicKeyAtPath(WalletAddressPath(accountIndex: 0, chainIndex: 0, keyIndex: 0))
    }
    
    func stopDiscovery() {
        guard discoveringLayout else {
            return
        }
        
        logger.info("Stoping discovery")
        currentAccount = nil
        discoveringLayout = false
    }
    
    // MARK: Internal methods
    
    private func fetchExtendedPublicKeyAtPath(addressPath: WalletAddressPath) {
        guard discoveringLayout else { return }
        
        // get or fetch account
        if currentAccount != nil {
            fetchAddressesAtPath(addressPath)
        }
        else {
            logger.info("Treating account with index \(addressPath.accountIndex)")
            storeProxy.fetchDiscoverableAccountWithIndex(addressPath.accountIndex) { [weak self] account in
                guard let strongSelf = self where strongSelf.discoveringLayout else { return }

                guard let account = account else {
                    strongSelf.logger.warn("Unable to fetch account with index \(addressPath.accountIndex), aborting")
                    strongSelf.stopDiscovery()
                    // TODO: NOTIFY
                    return
                }
                strongSelf.currentAccount = account
                strongSelf.fetchAddressesAtPath(addressPath)
            }
        }
    }
    
    private func fetchAddressesAtPath(addressPath: WalletAddressPath) {
        guard discoveringLayout else { return }
        
        // generate all paths
        var paths: [WalletAddressPath] = []
        let maxKeyIndex = addressPath.keyIndex + keyIncrement
        for var i = addressPath.keyIndex; i < maxKeyIndex; ++i {
            paths.append(WalletAddressPath(accountIndex: addressPath.accountIndex, chainIndex: addressPath.chainIndex, keyIndex: i))
        }
        
        // get or create addresses
        let currentPaths = "\(addressPath.relativePath)-\(maxKeyIndex)"
        logger.info("Treating addresses with paths \(currentPaths)")
        storeProxy.fetchAddressesWithPaths(paths) { [weak self] addresses in
            guard let strongSelf = self where strongSelf.discoveringLayout else { return }
            
            // check if all addresses are known
            guard addresses.count == paths.count else {
                // cache for missing paths
                let gotPaths = addresses.map({ $0.addressPath })
                strongSelf.logger.info("Some addresses in range \(currentPaths) are unknown, caching missing ones from xpub")
                strongSelf.cacheMissingAddressesAtPath(addressPath, expectedPaths: paths, fetchedPaths: gotPaths, existingAddresses: addresses)
                return
            }
            // all addresses are known
            strongSelf.logger.info("Addresses in range \(currentPaths) are known, fetching transactions")
            strongSelf.fetchTransactionsAtPath(addressPath, addresses: addresses)
        }
    }
    
    private func cacheMissingAddressesAtPath(addressPath: WalletAddressPath, expectedPaths: [WalletAddressPath], fetchedPaths: [WalletAddressPath], existingAddresses: [WalletCacheAddress]) {
        guard discoveringLayout else { return }
        
        let missingPaths: [WalletAddressPath] = expectedPaths.filter({ !fetchedPaths.contains($0) })
        let maxKeyIndex = addressPath.keyIndex + keyIncrement
        let currentPaths = "\(addressPath.relativePath)-\(maxKeyIndex)"

        // store missing paths
        logger.info("Generating missing addresses in range \(currentPaths)")
        generateNewAddressesAtPaths(missingPaths) { [weak self] generatedAddresses in
            guard let strongSelf = self where strongSelf.discoveringLayout else { return }
            
            // store generated addresses
            strongSelf.storeProxy.storeAddresses(generatedAddresses)
            
            // we now have all addresses known
            strongSelf.logger.info("Caching addresses in range \(currentPaths) done, fetching transactions")
            strongSelf.fetchTransactionsAtPath(addressPath, addresses: existingAddresses + generatedAddresses)
        }
    }
    
    private func generateNewAddressesAtPaths(missingPaths: [WalletAddressPath], completion: ([WalletCacheAddress]) -> Void) {
        guard missingPaths.count > 0 && discoveringLayout else {
            completion([])
            return
        }
        
        // create addresses from xpub
        dispatchAsyncOnGlobalQueueWithPriority(DISPATCH_QUEUE_PRIORITY_DEFAULT) { [weak self] in
            guard let strongSelf = self where strongSelf.discoveringLayout else { return }
            
            var cacheAddresses: [WalletCacheAddress] = []
            let keychain = BTCKeychain(extendedKey: strongSelf.currentAccount.extendedPublicKey)
            for path in missingPaths {
                let address = keychain.keyWithPath(path.chainPath).address.string
                cacheAddresses.append(WalletCacheAddress(addressPath: path, address: address))
            }
            dispatchAsyncOnMainQueue() { [weak self] in
                guard let strongSelf = self where strongSelf.discoveringLayout else { return }

                completion(cacheAddresses)
            }
        }
    }
    
    private func fetchTransactionsAtPath(addressPath: WalletAddressPath, addresses: [WalletCacheAddress]) {
        guard discoveringLayout else { return }
        
        // fetching transactions with addresses from API
        restClient.fetchTransactionsForAddresses(addresses.map() { return $0.address }) { [weak self] transactions in
            guard let strongSelf = self where strongSelf.discoveringLayout else { return }

            guard let transactions = transactions else {
                strongSelf.continueDiscoveryAtPath(addressPath, foundDeadEnd: false)
                return
            }
            // TODO: NOTIFY
            strongSelf.continueDiscoveryAtPath(addressPath, foundDeadEnd: transactions.count == 0)
        }
    }
    
    private func continueDiscoveryAtPath(addressPath: WalletAddressPath, foundDeadEnd: Bool) {
        if !foundDeadEnd {
            let newAddressPath = WalletAddressPath(accountIndex: addressPath.accountIndex, chainIndex: addressPath.chainIndex, keyIndex: addressPath.keyIndex + keyIncrement)
            logger.info("Dead end not found, continuing on the same chain at path \(newAddressPath.relativePath)")
            fetchExtendedPublicKeyAtPath(newAddressPath)
        }
        else {
            if addressPath.chainIndex >= 1 {
                let newAddressPath = WalletAddressPath(accountIndex: addressPath.accountIndex + 1, chainIndex: 0, keyIndex: 0)
                logger.info("Dead end found, continuing on the next account at path \(newAddressPath.relativePath)")
                currentAccount = nil
                fetchExtendedPublicKeyAtPath(newAddressPath)
            }
            else {
                let newAddressPath = WalletAddressPath(accountIndex: addressPath.accountIndex, chainIndex: addressPath.chainIndex + 1, keyIndex: 0)
                logger.info("Dead end found, continuing on the next chain at path \(newAddressPath.relativePath)")
                fetchExtendedPublicKeyAtPath(newAddressPath)
            }
        }
    }

    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy) {
        self.storeProxy = storeProxy
    }
    
}