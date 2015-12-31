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
    
    private let transactionsConsumer: WalletTransactionsConsumer
    private let transactionsListener: WalletTransactionsListener
    private let transactionsStream: WalletTransactionsStream
    
    private let logger = Logger.sharedInstance(name: "WalletAPIManager")
    private let delegateQueue = NSOperationQueue.mainQueue()
    
    // MARK: Wallet management
    
    func startRefreshingTransactions() {
        transactionsConsumer.delegate = self
        transactionsConsumer.startRefreshing()
    }
    
    func stopRefreshingTransactions() {
        transactionsConsumer.stopRefreshing()
    }
    
    func startListeningTransactions() {
        transactionsListener.delegate = self
        transactionsListener.startListening()
    }
    
    func stopListeningTransactions() {
        transactionsListener.stopListening()
    }
    
    func startAllServices() {
        startRefreshingTransactions()
        //startListeningTransactions()
    }
    
    func stopAllServices() {
        stopRefreshingTransactions()
        stopListeningTransactions()
    }
    
    // MARK: Utils
    
    private func registerAccount(account: WalletAccount) {
        // add account
        storeProxy.addAccount(account)
        
        // reload layout
        layoutHolder.reload()
        
        // cache 20 first internal + external addresses
        let internalPaths = (0..<WalletLayoutHolder.BIP44AddressesGap).map() { return WalletAddressPath(accountIndex: account.index, chainIndex: 0, keyIndex: $0) }
        let externalPaths = (0..<WalletLayoutHolder.BIP44AddressesGap).map() { return WalletAddressPath(accountIndex: account.index, chainIndex: 1, keyIndex: $0) }
        addressCache.fetchOrDeriveAddressesAtPaths(internalPaths + externalPaths, queue: NSOperationQueue.mainQueue(), completion: { _ in })
    }
    
    // MARK: Initialization

    init(uniqueIdentifier: String) {
        self.uniqueIdentifier = uniqueIdentifier
    
        // open store
        let storeURL = NSURL(fileURLWithPath: (ApplicationManager.sharedInstance.databasesDirectoryPath as NSString).stringByAppendingPathComponent(uniqueIdentifier + ".sqlite"))
        self.store = WalletStoreManager.managedStoreAtURL(storeURL, uniqueIdentifier: uniqueIdentifier)
        
        // create services
        self.storeProxy = WalletStoreProxy(store: store)
        self.addressCache = WalletAddressCache(storeProxy: storeProxy)
        self.layoutHolder = WalletLayoutHolder(storeProxy: storeProxy)
        self.transactionsConsumer = WalletTransactionsConsumer(addressCache: addressCache, delegateQueue: NSOperationQueue.mainQueue())
        self.transactionsListener = WalletTransactionsListener(delegateQueue: NSOperationQueue.mainQueue())
        self.transactionsStream = WalletTransactionsStream(storeProxy: storeProxy, addressCache: addressCache, layoutHolder: layoutHolder, delegateQueue: NSOperationQueue.mainQueue())
        
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
        let accounts = [
            WalletAccount(index: 0, extendedPublicKey: "xpub6Cec5KTvWeSNEw9bHe5v5sFPRwpM1x86Scuu7FuBpsQrhBg5GjhhBePAxpUQxmX8RNdAW2rfxZPQrrE5JAUqaa7MRfnXGKjQJB2awZ7Qgxy", name: nil),
            WalletAccount(index: 1, extendedPublicKey: "xpub6Cec5KTvWeSNG1BsXpNab628WvCGZEECqiHPY7JcBWSQgKfQN5wK4hUr3e9PM464Q7u9owCNHKTRGNGMxYdfPgUFZ3hR3ko2ap7xqxHmCxk", name: nil),
            WalletAccount(index: 2, extendedPublicKey: "xpub6Cec5KTvWeSNJtrFK6PqoCoP369xG8HYEDswqmTsQq63frkqF6dqYV56qRjJ7VQn1TEaejBPowG9vMGxVhsfRinhTgH5fTcAvMedABC8w6P", name: nil),
            WalletAccount(index: 3, extendedPublicKey: "xpub6Cec5KTvWeSNLwb2fMVRYVJn4w49WebLyg7cJM2QsbQotPggFX49H8jKvieYCMHaGCsKrW9VVknSt7KRxRuacasuGyJm74hZ4JeNRdsRB6Y", name: nil),
            WalletAccount(index: 4, extendedPublicKey: "xpub6Cec5KTvWeSNQLuVYmj4JZkX8q3VpSoQRd4BRkcPmhQvDaFi3yPobQXW795SLwN9zHXv9vYJyt4FrkWRBuJZMrg81qx7BDxNffPtJmFg2mb", name: nil)
        ]
//        let accounts = [
//            WalletAccountModel(index: 0, extendedPublicKey: "xpub6C47CZq7qLLXHgpoSdpBfjvxBz4YcnY4qXcgbbeeZGiSdyUDugFN3XMLavrUmdedGgaQaQRgVau69dUtoLQvgE1kSXHKWAQfiZHU7hGR2TX", name: nil)
//        ]
        guard index < accounts.count else {
            continueBlock(false)
            return
        }
        registerAccount(accounts[index])
        continueBlock(true)
    }

    func transactionsConsumer(transactionsConsumer: WalletTransactionsConsumer, didDiscoverTransactions transactions: [WalletRemoteTransaction]) {
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
    
    func transactionsListener(transactionsListener: WalletTransactionsListener, didReceiveTransaction transaction: WalletRemoteTransaction) {
        transactionsStream.enqueueTransactions([transaction])
    }
    
}