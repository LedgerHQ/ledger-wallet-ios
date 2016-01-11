//
//  WalletAPIManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletAPIManager: WalletManagerType {
    
    let uniqueIdentifier: String
    
    var isRefreshingTransactions: Bool { return transactionsConsumer.isRefreshing }
    var isListeningTransactions: Bool { return transactionsListener.isListening }
    
    private let store: SQLiteStore
    private let storeProxy: WalletStoreProxy
    private let addressCache: WalletAddressCache
    private let layoutHolder: WalletLayoutHolder
    private let balanceUpdater: WalletBalanceUpdater
    private let transactionsConsumer: WalletTransactionsConsumer
    private let transactionsListener: WalletTransactionsListener
    private let transactionsStream: WalletTransactionsStream
    private let logger = Logger.sharedInstance(name: "WalletAPIManager")
    private let delegateQueue = NSOperationQueue.mainQueue()
    private let workingQueue = NSOperationQueue.mainQueue()
    
    // MARK: Wallet management
    
    func startRefreshingTransactions() {
        transactionsConsumer.startRefreshing()
    }
    
    func stopRefreshingTransactions() {
        transactionsConsumer.stopRefreshing()
    }
    
    func startListeningTransactions() {
        transactionsListener.startListening()
    }
    
    func stopListeningTransactions() {
        transactionsListener.stopListening()
    }
    
    func startAllServices() {
        balanceUpdater.updateAccountBalances()
        startRefreshingTransactions()
        startListeningTransactions()
    }
    
    func stopAllServices() {
        stopRefreshingTransactions()
        stopListeningTransactions()
    }
    
    // MARK: Utils
    
    private func registerAccount(account: WalletAccount) {
        // add account
        storeProxy.addAccount(account, queue: workingQueue, completion: { _ in })
        
        // reload layout
        layoutHolder.reload()
        
        // cache 20 first internal + external addresses
        let internalPaths = (0..<WalletLayoutHolder.BIP44AddressesGap).map() { return WalletAddressPath(accountIndex: account.index, chainIndex: 0, keyIndex: $0) }
        let externalPaths = (0..<WalletLayoutHolder.BIP44AddressesGap).map() { return WalletAddressPath(accountIndex: account.index, chainIndex: 1, keyIndex: $0) }
        addressCache.fetchOrDeriveAddressesAtPaths(internalPaths + externalPaths, queue: workingQueue, completion: { _ in })
    }
    
    private func handleMissingAccountAtIndex(index: Int, continueBlock: (Bool) -> Void) {
        let accounts = [
            WalletAccount(index: 0, extendedPublicKey: "xpub67tVq9TLPPoaJgTkpz64N6YtB9pCorrwkLjqNgrnxWgGSVBkg2F7WhhRz5eBy7tEb2ZST4RUsC4iuMNGnWbQG69gPrTKmSKZMT3Xo7p9H4n", name: nil),
            WalletAccount(index: 1, extendedPublicKey: "xpub6D4waFVPfPCpUjYZexFNXjxusXSa5WrRj2iU8v5U6x2EvVuHaSKuo1zQEJA6Lt9dRcjgM1CSQmyq3tmSj5jCSup6WC24vRrHrBUyZkv5Jem", name: nil),
            WalletAccount(index: 2, extendedPublicKey: "xpub6D4waFVPfPCpX183njE1zjMayNCAnMHV4D989WsFd8ENDwfcdogPfRXSaA4opz3qoLoyCZCHZy9F7GQQnBxF4nNmZfXKKiokb2ABY8Bi8Jz", name: nil),
            WalletAccount(index: 3, extendedPublicKey: "xpub6D4waFVPfPCpZtpCLcfWBKLy2BqmWxDGuYVn4DmHyDSeVUDzjD5AsHy98SDmyXoiKmLWpsdfZszbcveZzFaEY6NhZSqw476xXu8LYBosvbG", name: nil),
        ]
//        let accounts = [
//            WalletAccount(index: 0, extendedPublicKey: "xpub6Cec5KTvWeSNEw9bHe5v5sFPRwpM1x86Scuu7FuBpsQrhBg5GjhhBePAxpUQxmX8RNdAW2rfxZPQrrE5JAUqaa7MRfnXGKjQJB2awZ7Qgxy", name: nil),
//            WalletAccount(index: 1, extendedPublicKey: "xpub6Cec5KTvWeSNG1BsXpNab628WvCGZEECqiHPY7JcBWSQgKfQN5wK4hUr3e9PM464Q7u9owCNHKTRGNGMxYdfPgUFZ3hR3ko2ap7xqxHmCxk", name: nil),
//            WalletAccount(index: 2, extendedPublicKey: "xpub6Cec5KTvWeSNJtrFK6PqoCoP369xG8HYEDswqmTsQq63frkqF6dqYV56qRjJ7VQn1TEaejBPowG9vMGxVhsfRinhTgH5fTcAvMedABC8w6P", name: nil),
//            WalletAccount(index: 3, extendedPublicKey: "xpub6Cec5KTvWeSNLwb2fMVRYVJn4w49WebLyg7cJM2QsbQotPggFX49H8jKvieYCMHaGCsKrW9VVknSt7KRxRuacasuGyJm74hZ4JeNRdsRB6Y", name: nil),
//            WalletAccount(index: 4, extendedPublicKey: "xpub6Cec5KTvWeSNQLuVYmj4JZkX8q3VpSoQRd4BRkcPmhQvDaFi3yPobQXW795SLwN9zHXv9vYJyt4FrkWRBuJZMrg81qx7BDxNffPtJmFg2mb", name: nil)
//        ]
        //        let accounts = [
        //            WalletAccountModel(index: 0, extendedPublicKey: "xpub6C47CZq7qLLXHgpoSdpBfjvxBz4YcnY4qXcgbbeeZGiSdyUDugFN3XMLavrUmdedGgaQaQRgVau69dUtoLQvgE1kSXHKWAQfiZHU7hGR2TX", name: nil)
        //        ]
        guard let account = accounts.filter({ $0.index == index }).first else {
            continueBlock(false)
            return
        }
        registerAccount(account)
        continueBlock(true)
    }
    
    // MARK: Initialization

    init(uniqueIdentifier: String, servicesProvider: ServicesProviderType) {
        self.uniqueIdentifier = uniqueIdentifier
        logger.info("Using services provider \"\(servicesProvider.name)\" with coin network \"\(servicesProvider.coinNetwork.name)\"")
    
        // open store
        let storeURL = NSURL(fileURLWithPath: (ApplicationManager.sharedInstance.databasesDirectoryPath as NSString).stringByAppendingPathComponent(uniqueIdentifier + ".sqlite"))
        self.store = WalletStoreManager.managedStoreAtURL(storeURL, uniqueIdentifier: uniqueIdentifier)
        
        // create services
        self.storeProxy = WalletStoreProxy(store: store)
        self.addressCache = WalletAddressCache(storeProxy: storeProxy)
        self.layoutHolder = WalletLayoutHolder(storeProxy: storeProxy)
        self.balanceUpdater = WalletBalanceUpdater(storeProxy: storeProxy, delegateQueue: workingQueue)
        self.transactionsConsumer = WalletTransactionsConsumer(addressCache: addressCache, servicesProvider: servicesProvider, delegateQueue: workingQueue)
        self.transactionsListener = WalletTransactionsListener(servicesProvider: servicesProvider, delegateQueue: workingQueue)
        self.transactionsStream = WalletTransactionsStream(storeProxy: storeProxy, addressCache: addressCache, layoutHolder: layoutHolder, delegateQueue: workingQueue)
        
        // plug delegates
        self.balanceUpdater.delegate = self
        self.transactionsConsumer.delegate = self
        self.transactionsListener.delegate = self
        self.transactionsStream.delegate = self
        
        // start services
        startAllServices()
    }
    
    deinit {
        stopAllServices()
        store.close()
    }
    
}

// MARK: - Notifications management

extension WalletAPIManager {
    
    private func notifyObservers(notification: String, userInfo: [String: AnyObject]? = nil) {
        delegateQueue.addOperationWithBlock() {
            NSNotificationCenter.defaultCenter().postNotificationName(notification, object: self, userInfo: userInfo)
        }
    }
    
}

// MARK: - WalletTransactionsConsumerDelegate

extension WalletAPIManager: WalletTransactionsConsumerDelegate {
    
    func transactionsConsumerDidStart(transactionsConsumer: WalletTransactionsConsumer) {
        notifyObservers(WalletManagerDidStartRefreshingTransactionsNotification)
    }
    
    func transactionsConsumer(transactionsConsumer: WalletTransactionsConsumer, didStopWithError error: WalletTransactionsConsumerError?) {
        notifyObservers(WalletManagerDidStopRefreshingTransactionsNotification)
    }
    
    func transactionsConsumer(transactionsConsumer: WalletTransactionsConsumer, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void) {
        handleMissingAccountAtIndex(index, continueBlock: continueBlock)
    }

    func transactionsConsumer(transactionsConsumer: WalletTransactionsConsumer, didDiscoverTransactions transactions: [WalletTransactionContainer]) {
        transactionsStream.enqueueTransactions(transactions)
    }
    
}

// MARK: - WalletTransactionsListenerDelegate

extension WalletAPIManager: WalletTransactionsListenerDelegate {
    
    func transactionsListenerDidStart(transactionsListener: WalletTransactionsListener) {
        notifyObservers(WalletManagerDidStartListeningTransactionsNotification)
    }
    
    func transactionsListenerDidStop(transactionsListener: WalletTransactionsListener) {
        notifyObservers(WalletManagerDidStopListeningTransactionsNotification)
    }
    
    func transactionsListener(transactionsListener: WalletTransactionsListener, didReceiveTransaction transaction: WalletTransactionContainer) {
        transactionsStream.enqueueTransactions([transaction])
    }
    
}

// MARK: - WalletTransactionsStreamDelegate

extension WalletAPIManager: WalletTransactionsStreamDelegate {
    
    func transactionsStreamDidStartDequeuingTransactions(transactionsStream: WalletTransactionsStream) {
        
    }
    
    func transactionsStreamDidStopDequeuingTransactions(transactionsStream: WalletTransactionsStream) {
        balanceUpdater.updateAccountBalances()
    }
    
    func transactionsStream(transactionsStream: WalletTransactionsStream, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void) {
        handleMissingAccountAtIndex(index, continueBlock: continueBlock)
    }
    
    func transactionsStreamDidUpdateAccountLayouts(transactionsStream: WalletTransactionsStream) {
        
    }
    
    func transactionsStreamDidUpdateOperations(transactionsStream: WalletTransactionsStream) {
        
    }
    
    func transactionsStreamDidUpdateDoubleSpendConflicts(transactionsStream: WalletTransactionsStream) {
        
    }
    
}

// MARK: - WalletBalanceUpdaterDelegate

extension WalletAPIManager: WalletBalanceUpdaterDelegate {
    
    func balanceUpdaterDidUpdateAccountBalances(balanceUpdater: WalletBalanceUpdater) {
        
    }
    
}