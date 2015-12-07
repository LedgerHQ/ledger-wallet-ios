//
//  WalletLayoutDiscoverer.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

enum WalletLayoutDiscovererError: ErrorType {
    
    case MissingExtendedPublicKey(accountIndex: Int)
    case UnableToFetchTransactions
    case Internal
    
}

protocol WalletLayoutDiscovererDelegate: class {
    
    func layoutDiscoverDidStart(layoutDiscoverer: WalletLayoutDiscoverer)
    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, didStopWithError error: WalletLayoutDiscovererError?)
    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, didDiscoverTransactions transactions: [WalletRemoteTransaction])
    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, extendedPublicKeyAtIndex index: Int, providerBlock: (String?) -> Void)
    
}

final class WalletLayoutDiscoverer {
    
    private static let keyIncrement = 20
    private static let maxChainIndex = 1
    
    var isDiscovering: Bool { return discoveringLayout }
    weak var delegate: WalletLayoutDiscovererDelegate?
    private var discoveringLayout = false
    private let storeProxy: WalletStoreProxy
    private let restClient = TransactionsRESTClient()
    private let logger = Logger.sharedInstance(name: "WalletLayoutDiscoverer")
    private var currentRequest: WalletLayoutAddressRequest?
    private var foundTransactionsInCurrentAccount = false
    
    // MARK: Layout discovery
    
    func startDiscovery() {
        guard !discoveringLayout else {
            return
        }
        
        logger.info("Starting discovery")
        discoveringLayout = true
        currentRequest = nil
        foundTransactionsInCurrentAccount = false
        delegate?.layoutDiscoverDidStart(self)
        ApplicationManager.sharedInstance.startNetworkActivity()
        fetchNextAddressesFromPath(WalletAddressPath(), toKeyIndex: self.dynamicType.keyIncrement - 1)
    }
    
    func stopDiscovery() {
        self.stopDiscoveryWithError(nil)
    }
    
    private func stopDiscoveryWithError(error: WalletLayoutDiscovererError?) {
        guard discoveringLayout else {
            return
        }
        
        logger.info("Stopping discovery")
        discoveringLayout = false
        currentRequest = nil
        foundTransactionsInCurrentAccount = false
        ApplicationManager.sharedInstance.stopNetworkActivity()
        delegate?.layoutDiscover(self, didStopWithError: error)
    }
    
    // MARK: Internal methods
    
    private func fetchNextAddressesFromPath(path: WalletAddressPath, toKeyIndex keyIndex: Int) {
        guard discoveringLayout else { return }
        
        guard let request = WalletLayoutAddressRequest(fromPath: path, toKeyIndex: keyIndex) else {
            logger.error("Unable to create address request, aborting")
            stopDiscoveryWithError(.Internal)
            return
        }
        currentRequest = request
        currentRequest?.delegate = self
        currentRequest?.dataSource = self
        currentRequest?.resume()
    }
    
    private func continueDiscoveryWithFetchedTransactions(transactions: [WalletRemoteTransaction]) {
        guard discoveringLayout else { return }

        if transactions.count == 0 {
            if currentRequest!.fromPath.chainIndex >= self.dynamicType.maxChainIndex {
                if foundTransactionsInCurrentAccount {
                    // next account
                    foundTransactionsInCurrentAccount = false
                    let newAddressPath = currentRequest!.fromPath.pathWithNewAccountIndex(currentRequest!.fromPath.accountIndex + 1)
                    let newKeyIndex = self.dynamicType.keyIncrement - 1
                    logger.info("No transactions found, continuing on the next account in range \(newAddressPath.rangeStringToKeyIndex(newKeyIndex))")
                    fetchNextAddressesFromPath(newAddressPath, toKeyIndex: newKeyIndex)
                }
                else {
                    // stop discovery
                    logger.info("No transactions found for account \(currentRequest!.fromPath.accountIndex), stopping")
                    stopDiscovery()
                }
            }
            else {
                // next chain
                let newAddressPath = currentRequest!.fromPath.pathWithNewChainIndex(currentRequest!.fromPath.chainIndex + 1)
                let newKeyIndex = self.dynamicType.keyIncrement - 1
                logger.info("No transactions found, continuing on the next chain in range \(newAddressPath.rangeStringToKeyIndex(newKeyIndex))")
                fetchNextAddressesFromPath(newAddressPath, toKeyIndex: newKeyIndex)
            }
        }
        else {
            // next key
            delegate?.layoutDiscover(self, didDiscoverTransactions: transactions)
            foundTransactionsInCurrentAccount = true
            let newAddressPath = currentRequest!.fromPath.pathWithNewKeyIndex(currentRequest!.toKeyIndex + 1)
            let newKeyIndex = newAddressPath.keyIndex + self.dynamicType.keyIncrement - 1
            logger.info("Transactions found, continuing on the same chain in range \(newAddressPath.rangeStringToKeyIndex(newKeyIndex))")
            fetchNextAddressesFromPath(newAddressPath, toKeyIndex: newKeyIndex)
        }
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy) {
        self.storeProxy = storeProxy
    }
    
    deinit {
        stopDiscovery()
    }
    
}

extension WalletLayoutDiscoverer: WalletLayoutAddressRequestDelegate {
    
    // MARK: WalletLayoutAddressRequestDelegate
    
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, didFailWithError error: WalletLayoutAddressRequestError) {
        guard discoveringLayout else { return }
        
        switch error {
        case .MissingExtendedPublicKey(let index):
            stopDiscoveryWithError(.MissingExtendedPublicKey(accountIndex: index))
        case .Internal, .NoDelegateOrDataSource, .MissingAddresses:
            stopDiscoveryWithError(.Internal)
        }
    }
    
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, didSucceedWithAddresses addresses: [WalletCacheAddress]) {
        guard discoveringLayout else { return }
        
        // fetch transactions from API
        let currentPath = currentRequest!.fromPath.rangeStringToKeyIndex(currentRequest!.toKeyIndex)
        logger.info("Fetching transactions for addresses in range \(currentPath)")
        restClient.fetchTransactionsForAddresses(addresses.map() { return $0.address }) { [weak self] transactions in
            guard let strongSelf = self where strongSelf.discoveringLayout else { return }
            
            guard let transactions = transactions else {
                strongSelf.logger.error("Unable to fetch transactions in range \(currentPath), aborting")
                strongSelf.stopDiscoveryWithError(.UnableToFetchTransactions)
                return
            }
            strongSelf.continueDiscoveryWithFetchedTransactions(transactions)
        }
    }
    
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, didGenerateAddresses addresses: [WalletCacheAddress]) {
        // store newly generated addresses in store
        storeProxy.storeAddresses(addresses)
    }
    
}

extension WalletLayoutDiscoverer: WalletLayoutAddressRequestDataSource {
    
    // MARK: WalletLayoutAddressRequestDataSource
    
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, extendedPublicKeyAtIndex index: Int, providerBlock: (String?) -> Void) {
        guard discoveringLayout else { return }
        
        // try to get xpub from store
        storeProxy.fetchDiscoverableAccountWithIndex(index) { [weak self] account in
            guard let strongSelf = self else { return }
            
            // no account to serve xpub, asking delegate
            guard let account = account else {
                guard let delegate = strongSelf.delegate else {
                    strongSelf.logger.error("Unable to ask for an extended public key with no delegate, aborting")
                    strongSelf.stopDiscovery()
                    return
                }
                delegate.layoutDiscover(strongSelf, extendedPublicKeyAtIndex: index, providerBlock: providerBlock)
                return
            }
            providerBlock(account.extendedPublicKey)
        }
    }
    
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, addressesForPaths paths: [WalletAddressPath], providerBlock: ([WalletCacheAddress]?) -> Void) {
        guard discoveringLayout else { return }

        // try to get addresses from store
        storeProxy.fetchAddressesWithPaths(paths, completion: providerBlock)
    }
    
}
