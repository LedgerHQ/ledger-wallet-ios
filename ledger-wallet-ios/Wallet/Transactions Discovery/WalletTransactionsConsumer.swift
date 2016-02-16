//
//  WalletTransactionsConsumer.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

enum WalletTransactionsConsumerError: ErrorType {
    
    case MissesAccountAtIndex(Int)
    case UnableToFetchTransactions
    case Cancelled
    
}

protocol WalletTransactionsConsumerDelegate: class {
    
    func transactionsConsumerDidStart(transactionsConsumer: WalletTransactionsConsumer)
    func transactionsConsumer(transactionsConsumer: WalletTransactionsConsumer, didStopWithError error: WalletTransactionsConsumerError?)
    func transactionsConsumer(transactionsConsumer: WalletTransactionsConsumer, didDiscoverTransactions transactions: [WalletTransactionContainer])
    func transactionsConsumer(transactionsConsumer: WalletTransactionsConsumer, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void)
    
}

final class WalletTransactionsConsumer {
    
    private static let maxChainIndex = 1
    
    weak var delegate: WalletTransactionsConsumerDelegate?
    private var refreshing = false
    private var foundTransactionsInCurrentAccount = false
    private let apiClient: WalletTransactionsAPIClient
    private let addressCache: WalletAddressCache
    private let delegateQueue: NSOperationQueue
    private var workingQueue = NSOperationQueue(name: "WalletTransactionsConsumer", maxConcurrentOperationCount: 1)
    private let logger = Logger.sharedInstance(name: "WalletTransactionsConsumer")
    
    var isRefreshing: Bool {
        var refreshing = false
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            refreshing = strongSelf.refreshing
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return refreshing
    }
    
    // MARK: Layout discovery
    
    func startRefreshing() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self where !strongSelf.refreshing else { return }
            
            strongSelf.logger.info("Start refreshing transactions")
            strongSelf.refreshing = true
            strongSelf.foundTransactionsInCurrentAccount = false
            strongSelf.fetchNextAddressesFromPath(WalletAddressPath(BIP32AccountIndex: 0, chainIndex: 0, keyIndex: 0), toKeyIndex: WalletLayoutHolder.BIP44AddressesGap - 1)
            
            // notify delegate
            strongSelf.delegateQueue.addOperationWithBlock() { strongSelf.delegate?.transactionsConsumerDidStart(strongSelf) }
        }
    }
    
    func stopRefreshing() {
        stopRefreshingWithError(.Cancelled)
    }
    
    private func stopRefreshingWithError(error: WalletTransactionsConsumerError?) {
        apiClient.cancelAllTasks()
        workingQueue.cancelAllOperations()
        
        let cancelBlock = { [weak self] in
            guard let strongSelf = self where strongSelf.refreshing else { return }
            
            strongSelf.logger.info("Stop refreshing transactions")
            strongSelf.refreshing = false
            strongSelf.foundTransactionsInCurrentAccount = false
            
            // notify delegate
            strongSelf.delegateQueue.addOperationWithBlock() { strongSelf.delegate?.transactionsConsumer(strongSelf, didStopWithError: error) }
        }
        
        if NSOperationQueue.currentQueue() != workingQueue {
            workingQueue.addOperationWithBlock(cancelBlock)
            workingQueue.waitUntilAllOperationsAreFinished()
        }
        else {
            cancelBlock()
        }
    }
    
    // MARK: Internal methods
    
    private func fetchNextAddressesFromPath(path: WalletAddressPath, toKeyIndex keyIndex: Int) {
        // generate all paths
        var requestedPaths: [WalletAddressPath] = []
        for i in path.BIP32KeyIndex!...keyIndex { requestedPaths.append(WalletAddressPath(BIP32AccountIndex: path.BIP32AccountIndex!, chainIndex: path.BIP32ChainIndex!, keyIndex: i)) }

        // get addresses
        logger.info("Fetching addresses for paths in range \(path.rangeStringToIndex(keyIndex))")
        addressCache.fetchOrDeriveAddressesAtPaths(requestedPaths, queue: workingQueue) { [weak self] addresses in
            guard let strongSelf = self where strongSelf.refreshing else { return }
            
            // check we got the addresses
            guard let addresses = addresses else {
                // ask delegate for missing account
                strongSelf.askDelegateForAccountAtIndex(path.BIP32AccountIndex!, requestedPaths: requestedPaths, startingPath: path, toKeyIndex: keyIndex)
                return
            }
        
            // fetch transactions
            strongSelf.fetchTransactionsForAddresses(addresses, startingPath: path, toKeyIndex: keyIndex)
        }
    }
    
    private func askDelegateForAccountAtIndex(accountIndex: Int, requestedPaths: [WalletAddressPath], startingPath: WalletAddressPath, toKeyIndex keyIndex: Int) {
        logger.warn("Unknown account at index \(requestedPaths.first!.BIP32AccountIndex!), asking delegate")
        
        let continueBlock = { [weak self] (shouldContinue: Bool) in
            guard let strongSelf = self where strongSelf.refreshing else { return }
            
            // check if we should retry
            guard shouldContinue == true else {
                strongSelf.logger.error("Delegate failed to provide account at index \(accountIndex), aborting")
                strongSelf.stopRefreshingWithError(.MissesAccountAtIndex(accountIndex))
                return
            }
            
            // get addresses
            strongSelf.logger.info("Delegate provided account at index \(accountIndex), retrying")
            strongSelf.addressCache.fetchOrDeriveAddressesAtPaths(requestedPaths, queue: strongSelf.workingQueue) { [weak self] addresses in
                guard let strongSelf = self where strongSelf.refreshing else { return }
                
                guard let addresses = addresses else {
                    strongSelf.logger.error("Still no account at index \(accountIndex), aborting")
                    strongSelf.stopRefreshingWithError(.MissesAccountAtIndex(accountIndex))
                    return
                }
                
                // fetch transactions
                strongSelf.fetchTransactionsForAddresses(addresses, startingPath: startingPath, toKeyIndex: keyIndex)
            }
        }
        
        // ask delegate
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.transactionsConsumer(strongSelf, didMissAccountAtIndex: accountIndex) { [weak self] shouldContinue in
                guard let strongSelf = self else { return }
                
                strongSelf.workingQueue.addOperationWithBlock() { continueBlock(shouldContinue) }
            }
        }
    }
    
    private func fetchTransactionsForAddresses(addresses: [WalletAddress], startingPath: WalletAddressPath, toKeyIndex keyIndex: Int) {
        // fetch transactions from API
        let currentPath = startingPath.rangeStringToIndex(keyIndex)
        logger.info("Fetching transactions for addresses in range \(currentPath)")
        apiClient.fetchTransactionsForAddresses(addresses.map() { return $0.address }) { [weak self] transactions in
            guard let strongSelf = self where strongSelf.refreshing else { return }
            
            guard let transactions = transactions else {
                strongSelf.logger.error("Unable to fetch transactions in range \(currentPath), aborting")
                strongSelf.stopRefreshingWithError(.UnableToFetchTransactions)
                return
            }
            
            // continue discovery at next indexes
            strongSelf.continueDiscoveryWithFetchedTransactions(transactions, startingPath: startingPath, toKeyIndex: keyIndex)
        }
    }
    
    private func continueDiscoveryWithFetchedTransactions(transactions: [WalletTransactionContainer], startingPath: WalletAddressPath, toKeyIndex keyIndex: Int) {
        // check it is is the end of discovery
        if transactions.count == 0 {
            // if we are already on the last chain index
            if startingPath.BIP32ChainIndex! >= self.dynamicType.maxChainIndex {
                if foundTransactionsInCurrentAccount {
                    // next account
                    foundTransactionsInCurrentAccount = false
                    let newAddressPath = startingPath.pathWithNewBIP32AccountIndex(startingPath.BIP32AccountIndex! + 1)
                    let newKeyIndex = WalletLayoutHolder.BIP44AddressesGap - 1
                    logger.info("No transactions found, continuing on the next account in range \(newAddressPath.rangeStringToIndex(newKeyIndex))")
                    fetchNextAddressesFromPath(newAddressPath, toKeyIndex: newKeyIndex)
                }
                else {
                    // stop discovery
                    logger.info("No transactions found for account \(startingPath.BIP32AccountIndex!), stopping")
                    stopRefreshingWithError(nil)
                }
            }
            else {
                // next chain
                let newAddressPath = startingPath.pathWithNewBIP32ChainIndex(startingPath.BIP32ChainIndex! + 1)!
                let newKeyIndex = WalletLayoutHolder.BIP44AddressesGap - 1
                logger.info("No transactions found, continuing on the next chain in range \(newAddressPath.rangeStringToIndex(newKeyIndex))")
                fetchNextAddressesFromPath(newAddressPath, toKeyIndex: newKeyIndex)
            }
        }
        else {
            // notify delegate
            logger.info("Discovered \(transactions.count) transactions")
            delegateQueue.addOperationWithBlock() { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.transactionsConsumer(strongSelf, didDiscoverTransactions: transactions)
            }
            
            // next key
            foundTransactionsInCurrentAccount = true
            let newAddressPath = startingPath.pathWithBIP32KeyIndex(keyIndex + 1)!
            let newKeyIndex = newAddressPath.BIP32KeyIndex! + WalletLayoutHolder.BIP44AddressesGap - 1
            logger.info("Transactions found, continuing on the same chain in range \(newAddressPath.rangeStringToIndex(newKeyIndex))")
            fetchNextAddressesFromPath(newAddressPath, toKeyIndex: newKeyIndex)
        }
    }
    
    // MARK: Initialization
    
    init(addressCache: WalletAddressCache, servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        self.addressCache = addressCache
        self.apiClient = WalletTransactionsAPIClient(servicesProvider: servicesProvider, delegateQueue: self.workingQueue)
    }
    
    deinit {
        stopRefreshingWithError(nil)
    }

}
