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
    
    private let transactionsConsumer: WalletTransactionsConsumer
    private let transactionsListener: WalletTransactionsListener
    private let transactionsStream: WalletTransactionsStream
    private let store: SQLiteStore
    private let externalStoreProxy: WalletStoreProxy
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
    
    func registerAccount(account: WalletAccountModel) {
        let internalPaths = (0..<20).map() { return WalletAddressPath(accountIndex: account.index, chainIndex: 0, keyIndex: $0) }
        let externalPaths = (0..<20).map() { return WalletAddressPath(accountIndex: account.index, chainIndex: 1, keyIndex: $0) }
        externalStoreProxy.addAccount(account)
        externalStoreProxy.fetchAddressesAtPaths(internalPaths + externalPaths, completion: { _ in })
        // TODO: Call address cache, not proxy to store adresses
        transactionsStream.reloadLayout()
    }
    
    // MARK: Initialization

    init(uniqueIdentifier: String) {
        self.uniqueIdentifier = uniqueIdentifier
    
        // open store
        let storeURL = NSURL(fileURLWithPath: (ApplicationManager.sharedInstance.databasesDirectoryPath as NSString).stringByAppendingPathComponent(uniqueIdentifier + ".sqlite"))
        self.store = WalletStoreManager.managedStoreAtURL(storeURL, uniqueIdentifier: uniqueIdentifier)
        self.externalStoreProxy = WalletStoreProxy(store: store, delegateQueue: NSOperationQueue.mainQueue())
        
        // create services
        self.transactionsConsumer = WalletTransactionsConsumer(store: store, delegateQueue: NSOperationQueue.mainQueue())
        self.transactionsListener = WalletTransactionsListener(delegateQueue: NSOperationQueue.mainQueue())
        self.transactionsStream = WalletTransactionsStream(store: store, delegateQueue: NSOperationQueue.mainQueue())
        
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
//        let accounts: [WalletAccountModel] = [
//            WalletAccountModel(index: 0, extendedPublicKey: "xpub6Cec5KTvWeSNEw9bHe5v5sFPRwpM1x86Scuu7FuBpsQrhBg5GjhhBePAxpUQxmX8RNdAW2rfxZPQrrE5JAUqaa7MRfnXGKjQJB2awZ7Qgxy", name: nil),
//            WalletAccountModel(index: 1, extendedPublicKey: "xpub6Cec5KTvWeSNG1BsXpNab628WvCGZEECqiHPY7JcBWSQgKfQN5wK4hUr3e9PM464Q7u9owCNHKTRGNGMxYdfPgUFZ3hR3ko2ap7xqxHmCxk", name: nil),
//            WalletAccountModel(index: 2, extendedPublicKey: "xpub6Cec5KTvWeSNJtrFK6PqoCoP369xG8HYEDswqmTsQq63frkqF6dqYV56qRjJ7VQn1TEaejBPowG9vMGxVhsfRinhTgH5fTcAvMedABC8w6P", name: nil),
//            WalletAccountModel(index: 3, extendedPublicKey: "xpub6Cec5KTvWeSNLwb2fMVRYVJn4w49WebLyg7cJM2QsbQotPggFX49H8jKvieYCMHaGCsKrW9VVknSt7KRxRuacasuGyJm74hZ4JeNRdsRB6Y", name: nil),
//            WalletAccountModel(index: 4, extendedPublicKey: "xpub6Cec5KTvWeSNQLuVYmj4JZkX8q3VpSoQRd4BRkcPmhQvDaFi3yPobQXW795SLwN9zHXv9vYJyt4FrkWRBuJZMrg81qx7BDxNffPtJmFg2mb", name: nil)
//        ]
        let accounts: [WalletAccountModel] = [
            WalletAccountModel(index: 0, extendedPublicKey: "xpub6C47CZq7qLLXHgpoSdpBfjvxBz4YcnY4qXcgbbeeZGiSdyUDugFN3XMLavrUmdedGgaQaQRgVau69dUtoLQvgE1kSXHKWAQfiZHU7hGR2TX", name: nil)
        ]
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