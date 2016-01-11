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
    private let apiClient: TransactionsAPIClient
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
            strongSelf.fetchNextAddressesFromPath(WalletAddressPath(), toKeyIndex: WalletLayoutHolder.BIP44AddressesGap - 1)
            ApplicationManager.sharedInstance.startNetworkActivity()
            
            // notify delegate
            strongSelf.delegateQueue.addOperationWithBlock() { strongSelf.delegate?.transactionsConsumerDidStart(strongSelf) }
        }
    }
    
    func stopRefreshing() {
        self.stopRefreshingWithError(nil)
    }
    
    private func stopRefreshingWithError(error: WalletTransactionsConsumerError?) {
        apiClient.cancelAllTasks()
        workingQueue.cancelAllOperations()
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self where strongSelf.refreshing else { return }
        
            strongSelf.logger.info("Stop refreshing transactions")
            strongSelf.refreshing = false
            strongSelf.foundTransactionsInCurrentAccount = false
            ApplicationManager.sharedInstance.stopNetworkActivity()

            // notify delegate
            strongSelf.delegateQueue.addOperationWithBlock() { strongSelf.delegate?.transactionsConsumer(strongSelf, didStopWithError: error) }
        }
    }
    
    // MARK: Internal methods
    
    private func fetchNextAddressesFromPath(path: WalletAddressPath, toKeyIndex keyIndex: Int) {
        // generate all paths
        var requestedPaths: [WalletAddressPath] = []
        for i in path.keyIndex...keyIndex { requestedPaths.append(WalletAddressPath(accountIndex: path.accountIndex, chainIndex: path.chainIndex, keyIndex: i)) }

        // get addresses
        logger.info("Fetching addresses for paths in range \(path.rangeStringToKeyIndex(keyIndex))")
        addressCache.fetchOrDeriveAddressesAtPaths(requestedPaths, queue: workingQueue) { [weak self] addresses in
            guard let strongSelf = self where strongSelf.refreshing else { return }
            
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
        let currentPath = startingPath.rangeStringToKeyIndex(keyIndex)
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
                    stopRefreshingWithError(nil)
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
                strongSelf.delegate?.transactionsConsumer(strongSelf, didDiscoverTransactions: transactions)
            }
            
            // next key
            foundTransactionsInCurrentAccount = true
            let newAddressPath = startingPath.pathWithKeyIndex(keyIndex + 1)
            let newKeyIndex = newAddressPath.keyIndex + WalletLayoutHolder.BIP44AddressesGap - 1
            logger.info("Transactions found, continuing on the same chain in range \(newAddressPath.rangeStringToKeyIndex(newKeyIndex))")
            fetchNextAddressesFromPath(newAddressPath, toKeyIndex: newKeyIndex)
        }
    }
    
    // MARK: Initialization
    
    init(addressCache: WalletAddressCache, servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        self.addressCache = addressCache
        self.apiClient = TransactionsAPIClient(servicesProvider: servicesProvider, delegateQueue: self.workingQueue)
    }
    
    deinit {
        stopRefreshingWithError(nil)
        workingQueue.waitUntilAllOperationsAreFinished()
    }

}
