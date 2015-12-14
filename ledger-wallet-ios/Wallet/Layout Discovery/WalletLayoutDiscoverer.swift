//
//  WalletLayoutDiscoverer.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

enum WalletLayoutDiscovererError: ErrorType {
    
    case MissesAccountAtIndex(Int)
    case UnableToFetchTransactions
    
}

protocol WalletLayoutDiscovererDelegate: class {
    
    func layoutDiscoverDidStart(layoutDiscoverer: WalletLayoutDiscoverer)
    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, didStopWithError error: WalletLayoutDiscovererError?)
    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, didDiscoverTransactions transactions: [WalletRemoteTransaction])
    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void)
    
}

final class WalletLayoutDiscoverer {
    
    private static let maxChainIndex = 1
    
    weak var delegate: WalletLayoutDiscovererDelegate?
    private var discoveringLayout = false
    private var foundTransactionsInCurrentAccount = false
    private let apiClient: TransactionsAPIClient
    private let addressCache: WalletAddressCache
    private let delegateQueue: NSOperationQueue
    private var workingQueue = NSOperationQueue(name: "WalletLayoutDiscoverer", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletLayoutDiscoverer")
    
    var isDiscovering: Bool {
        var discovering = false
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            discovering = strongSelf.discoveringLayout
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return discovering
    }
    
    // MARK: Layout discovery
    
    func startDiscovery() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self where !strongSelf.discoveringLayout else { return }
            
            strongSelf.logger.info("Start discovering layout")
            strongSelf.discoveringLayout = true
            strongSelf.foundTransactionsInCurrentAccount = false
            strongSelf.fetchNextAddressesFromPath(WalletAddressPath(), toKeyIndex: WalletLayoutHolder.BIP44AddressesGap - 1)
            ApplicationManager.sharedInstance.startNetworkActivity()
            
            // notify delegate
            strongSelf.delegateQueue.addOperationWithBlock() { strongSelf.delegate?.layoutDiscoverDidStart(strongSelf) }
        }
    }
    
    func stopDiscovery() {
        self.stopDiscoveryWithError(nil)
    }
    
    private func stopDiscoveryWithError(error: WalletLayoutDiscovererError?) {
        apiClient.cancelAllTasks()
        workingQueue.cancelAllOperations()
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self where strongSelf.discoveringLayout else { return }
        
            strongSelf.logger.info("Stop discovering layout")
            strongSelf.discoveringLayout = false
            strongSelf.foundTransactionsInCurrentAccount = false
            ApplicationManager.sharedInstance.stopNetworkActivity()

            // notify delegate
            strongSelf.delegateQueue.addOperationWithBlock() { strongSelf.delegate?.layoutDiscover(strongSelf, didStopWithError: error) }
        }
    }
    
    // MARK: Internal methods
    
    private func fetchNextAddressesFromPath(path: WalletAddressPath, toKeyIndex keyIndex: Int) {
        // generate all paths
        var requestedPaths: [WalletAddressPath] = []
        for i in path.keyIndex...keyIndex { requestedPaths.append(WalletAddressPath(accountIndex: path.accountIndex, chainIndex: path.chainIndex, keyIndex: i)) }

        // get addresses
        logger.info("Fetching addresses for paths in range \(path.rangeStringToKeyIndex(keyIndex))")
        addressCache.addressesAtPaths(requestedPaths) { [weak self] addresses in
            guard let strongSelf = self where strongSelf.discoveringLayout else { return }
            
            // check we got the addresses
            guard let addresses = addresses else {
                // ask delegate for missing account
                strongSelf.askDelegateForAccountAtIndex(path.accountIndex, requestedPaths: requestedPaths, startingPath: path, toKeyIndex: keyIndex)
                return
            }
        
            // fetch transactions
            strongSelf.fetchTransactionsForAddresses(addresses, startingPath: path, toKeyIndex: keyIndex)
        }
    }
    
    private func askDelegateForAccountAtIndex(accountIndex: Int, requestedPaths: [WalletAddressPath], startingPath: WalletAddressPath, toKeyIndex keyIndex: Int) {
        logger.warn("Unknown account at index \(requestedPaths.first!.accountIndex), asking delegate")
        
        let continueBlock = { [weak self] (shouldContinue: Bool) in
            guard let strongSelf = self where strongSelf.discoveringLayout else { return }
            
            // check if we should retry
            guard shouldContinue == true else {
                strongSelf.logger.error("Delegate failed to provide account at index \(accountIndex), aborting")
                strongSelf.stopDiscoveryWithError(.MissesAccountAtIndex(accountIndex))
                return
            }
            
            // get addresses
            strongSelf.logger.info("Delegate provided account at index \(accountIndex), retrying")
            strongSelf.addressCache.addressesAtPaths(requestedPaths) { [weak self] addresses in
                guard let strongSelf = self where strongSelf.discoveringLayout else { return }
                
                guard let addresses = addresses else {
                    strongSelf.logger.error("Still no account at index \(accountIndex), aborting")
                    strongSelf.stopDiscoveryWithError(.MissesAccountAtIndex(accountIndex))
                    return
                }
                
                // fetch transactions
                strongSelf.fetchTransactionsForAddresses(addresses, startingPath: startingPath, toKeyIndex: keyIndex)
            }
        }
        
        // ask delegate
        delegateQueue.addOperationWithBlock() {
            self.delegate?.layoutDiscover(self, didMissAccountAtIndex: accountIndex) { [weak self] shouldContinue in
                guard let strongSelf = self else { return }
                strongSelf.workingQueue.addOperationWithBlock() { continueBlock(shouldContinue) }
            }
        }
    }
    
    private func fetchTransactionsForAddresses(addresses: [WalletAddressModel], startingPath: WalletAddressPath, toKeyIndex keyIndex: Int) {
        // fetch transactions from API
        let currentPath = startingPath.rangeStringToKeyIndex(keyIndex)
        logger.info("Fetching transactions for addresses in range \(currentPath)")
        apiClient.fetchTransactionsForAddresses(addresses.map() { return $0.address }) { [weak self] transactions in
            guard let strongSelf = self where strongSelf.discoveringLayout else { return }
            
            guard let transactions = transactions else {
                strongSelf.logger.error("Unable to fetch transactions in range \(currentPath), aborting")
                strongSelf.stopDiscoveryWithError(.UnableToFetchTransactions)
                return
            }
            
            // continue discovery at next indexes
            strongSelf.continueDiscoveryWithFetchedTransactions(transactions, startingPath: startingPath, toKeyIndex: keyIndex)
        }
    }
    
    private func continueDiscoveryWithFetchedTransactions(transactions: [WalletRemoteTransaction], startingPath: WalletAddressPath, toKeyIndex keyIndex: Int) {
        // check it is is the end of discovery
        if transactions.count == 0 {
            // if we are already on the last chain index
            if startingPath.chainIndex >= self.dynamicType.maxChainIndex {
                if foundTransactionsInCurrentAccount {
                    // next account
                    foundTransactionsInCurrentAccount = false
                    let newAddressPath = startingPath.pathWithNewAccountIndex(startingPath.accountIndex + 1)
                    let newKeyIndex = WalletLayoutHolder.BIP44AddressesGap - 1
                    logger.info("No transactions found, continuing on the next account in range \(newAddressPath.rangeStringToKeyIndex(newKeyIndex))")
                    fetchNextAddressesFromPath(newAddressPath, toKeyIndex: newKeyIndex)
                }
                else {
                    // stop discovery
                    logger.info("No transactions found for account \(startingPath.accountIndex), stopping")
                    stopDiscoveryWithError(nil)
                }
            }
            else {
                // next chain
                let newAddressPath = startingPath.pathWithNewChainIndex(startingPath.chainIndex + 1)
                let newKeyIndex = WalletLayoutHolder.BIP44AddressesGap - 1
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
            let newAddressPath = startingPath.pathWithNewKeyIndex(keyIndex + 1)
            let newKeyIndex = newAddressPath.keyIndex + WalletLayoutHolder.BIP44AddressesGap - 1
            logger.info("Transactions found, continuing on the same chain in range \(newAddressPath.rangeStringToKeyIndex(newKeyIndex))")
            fetchNextAddressesFromPath(newAddressPath, toKeyIndex: newKeyIndex)
        }
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore, delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        self.addressCache = WalletAddressCache(store: store, delegateQueue: self.workingQueue)
        self.apiClient = TransactionsAPIClient(delegateQueue: self.workingQueue)
    }
    
    deinit {
        stopDiscoveryWithError(nil)
        workingQueue.waitUntilAllOperationsAreFinished()
    }

}
