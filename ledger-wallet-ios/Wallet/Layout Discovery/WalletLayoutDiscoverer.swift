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
    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, accountAtIndex index: Int, providerBlock: (WalletAccount?) -> Void)
    
}

final class WalletLayoutDiscoverer {
    
    private static let keyIncrement = 20
    private static let maxChainIndex = 1
    
    weak var delegate: WalletLayoutDiscovererDelegate?
    private var currentRequest: WalletLayoutAddressRequest?
    private var discoveringLayout = false
    private var foundTransactionsInCurrentAccount = false
    private let delegateQueue: NSOperationQueue
    private let storeProxy: WalletStoreProxy
    private let apiClient: TransactionsAPIClient
    private var workingQueue = NSOperationQueue(name: "WalletLayoutDiscoverer", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletLayoutDiscoverer")
    
    var isDiscovering: Bool {
        var discovering = false
        workingQueue.addOperationWithBlock() {
            discovering = self.discoveringLayout
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return discovering
    }
    
    // MARK: Layout discovery
    
    func startDiscovery() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self where !strongSelf.discoveringLayout else { return }
            
            strongSelf.logger.info("Starting discovery")
            strongSelf.discoveringLayout = true
            strongSelf.currentRequest = nil
            strongSelf.foundTransactionsInCurrentAccount = false
            ApplicationManager.sharedInstance.startNetworkActivity()
            strongSelf.fetchNextAddressesFromPath(WalletAddressPath(), toKeyIndex: strongSelf.dynamicType.keyIncrement - 1)

            // notify delegate
            strongSelf.delegateQueue.addOperationWithBlock() { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.layoutDiscoverDidStart(strongSelf)
            }
        }
    }
    
    func stopDiscovery() {
        self.stopDiscoveryWithError(nil)
    }
    
    private func stopDiscoveryWithError(error: WalletLayoutDiscovererError?, wait: Bool = false) {
        apiClient.cancelAllTasks()
        workingQueue.cancelAllOperations()
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self where strongSelf.discoveringLayout else { return }
        
            strongSelf.logger.info("Stopping discovery")
            strongSelf.discoveringLayout = false
            strongSelf.currentRequest = nil
            strongSelf.foundTransactionsInCurrentAccount = false
            ApplicationManager.sharedInstance.stopNetworkActivity()

            // notify delegate
            strongSelf.delegateQueue.addOperationWithBlock() { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.layoutDiscover(strongSelf, didStopWithError: error)
            }
        }
        if wait {
            workingQueue.waitUntilAllOperationsAreFinished()
        }
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
        guard let currentRequest = currentRequest else {
            logger.info("No current request, stopping")
            stopDiscoveryWithError(.Internal)
            return
        }

        // check it is is the end of discovery
        if transactions.count == 0 {
            // if we are already on the last chain index
            if currentRequest.fromPath.chainIndex >= self.dynamicType.maxChainIndex {
                if foundTransactionsInCurrentAccount {
                    // next account
                    foundTransactionsInCurrentAccount = false
                    let newAddressPath = currentRequest.fromPath.pathWithNewAccountIndex(currentRequest.fromPath.accountIndex + 1)
                    let newKeyIndex = self.dynamicType.keyIncrement - 1
                    logger.info("No transactions found, continuing on the next account in range \(newAddressPath.rangeStringToKeyIndex(newKeyIndex))")
                    fetchNextAddressesFromPath(newAddressPath, toKeyIndex: newKeyIndex)
                }
                else {
                    // stop discovery
                    logger.info("No transactions found for account \(currentRequest.fromPath.accountIndex), stopping")
                    stopDiscoveryWithError(nil)
                }
            }
            else {
                // next chain
                let newAddressPath = currentRequest.fromPath.pathWithNewChainIndex(currentRequest.fromPath.chainIndex + 1)
                let newKeyIndex = self.dynamicType.keyIncrement - 1
                logger.info("No transactions found, continuing on the next chain in range \(newAddressPath.rangeStringToKeyIndex(newKeyIndex))")
                fetchNextAddressesFromPath(newAddressPath, toKeyIndex: newKeyIndex)
            }
        }
        else {
            // notify delegate
            delegateQueue.addOperationWithBlock() { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.layoutDiscover(strongSelf, didDiscoverTransactions: transactions)
            }
            
            // next key
            foundTransactionsInCurrentAccount = true
            let newAddressPath = currentRequest.fromPath.pathWithNewKeyIndex(currentRequest.toKeyIndex + 1)
            let newKeyIndex = newAddressPath.keyIndex + self.dynamicType.keyIncrement - 1
            logger.info("Transactions found, continuing on the same chain in range \(newAddressPath.rangeStringToKeyIndex(newKeyIndex))")
            fetchNextAddressesFromPath(newAddressPath, toKeyIndex: newKeyIndex)
        }
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore, delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        self.storeProxy = WalletStoreProxy(store: store, delegateQueue: self.workingQueue)
        self.apiClient = TransactionsAPIClient(delegateQueue: self.workingQueue)
    }
    
    deinit {
        stopDiscoveryWithError(nil, wait: true)
    }
    
}

// MARK: - WalletLayoutAddressRequestDelegate

extension WalletLayoutDiscoverer: WalletLayoutAddressRequestDelegate {
    
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, didFailWithError error: WalletLayoutAddressRequestError) {
        guard discoveringLayout else { return }
        
        switch error {
        case .MissingExtendedPublicKey(let index):
            stopDiscoveryWithError(.MissingExtendedPublicKey(accountIndex: index))
        case .Internal, .NoDelegateOrDataSource, .MissingAddresses:
            stopDiscoveryWithError(.Internal)
        }
    }
    
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, didSucceedWithAddresses addresses: [WalletAddress]) {
        guard discoveringLayout else { return }
        
        // fetch transactions from API
        let currentPath = currentRequest!.fromPath.rangeStringToKeyIndex(currentRequest!.toKeyIndex)
        logger.info("Fetching transactions for addresses in range \(currentPath)")
        apiClient.fetchTransactionsForAddresses(addresses.map() { return $0.address }) { [weak self] transactions in
            guard let strongSelf = self where strongSelf.discoveringLayout else { return }
            
            guard let transactions = transactions else {
                strongSelf.logger.error("Unable to fetch transactions in range \(currentPath), aborting")
                strongSelf.stopDiscoveryWithError(.UnableToFetchTransactions)
                return
            }
            
            // continue discovery at next indexes
            strongSelf.continueDiscoveryWithFetchedTransactions(transactions)
        }
    }
    
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, didGenerateAddresses addresses: [WalletAddress]) {
        // store newly generated addresses in store
        storeProxy.addAddresses(addresses)
    }
    
}

// MARK: - WalletLayoutAddressRequestDataSource

extension WalletLayoutDiscoverer: WalletLayoutAddressRequestDataSource {
    
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, accountAtIndex index: Int, providerBlock: (WalletAccount?) -> Void) {
        guard discoveringLayout else { return }
        
        // try to get account from store
        storeProxy.fetchAccountAtIndex(index) { [weak self] account in
            guard let strongSelf = self where strongSelf.discoveringLayout else { return }
            
            // no account to serve xpub, asking delegate
            guard let account = account else {
                guard let _ = strongSelf.delegate else {
                    strongSelf.logger.error("Unable to ask for an account with no delegate, aborting")
                    strongSelf.stopDiscoveryWithError(nil)
                    return
                }
                
                // notify delegate
                strongSelf.delegateQueue.addOperationWithBlock() { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.delegate?.layoutDiscover(strongSelf, accountAtIndex: index) { account in
                        strongSelf.workingQueue.addOperationWithBlock() { providerBlock(account) }
                    }
                }
                return
            }
            
            // we have the account, give it to request
            providerBlock(account)
        }
    }
    
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, addressesForPaths paths: [WalletAddressPath], providerBlock: ([WalletAddress]?) -> Void) {
        guard discoveringLayout else { return }

        // try to get addresses from store
        storeProxy.fetchAddressesAtPaths(paths) { [weak self] addresses in
            guard let strongSelf = self where strongSelf.discoveringLayout else { return }
            
            // give addresses to request
            providerBlock(addresses)
        }
    }
    
}
