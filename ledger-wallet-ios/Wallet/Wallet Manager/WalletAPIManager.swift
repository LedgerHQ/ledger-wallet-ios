//
//  WalletAPIManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

typealias WalletRemoteTransaction = [String: AnyObject]

final class WalletAPIManager: WalletManagerType {
    
    let uniqueIdentifier: String
    var isRefreshingLayout: Bool { return layoutDiscoverer.isDiscovering }
    var isListeningTransactions: Bool { return websocketListener.isListening }
    
    private let layoutDiscoverer: WalletLayoutDiscoverer
    private let websocketListener: WalletWebsocketListener
    private let transactionsStream: WalletTransactionsStream
    private let store: SQLiteStore
    private let externalStoreProxy: WalletStoreProxy
    private let logger = Logger.sharedInstance(name: "WalletAPIManager")
    private let delegateQueue = NSOperationQueue.mainQueue()
    
    // MARK: Wallet management
    
    func startRefreshingLayout() {
        layoutDiscoverer.delegate = self
        layoutDiscoverer.startDiscovery()
    }
    
    func stopRefreshingLayout() {
        layoutDiscoverer.stopDiscovery()
    }
    
    func startListeningTransactions() {
        websocketListener.delegate = self
        websocketListener.startListening()
    }
    
    func stopListeningTransactions() {
        websocketListener.stopListening()
    }
    
    func startAllServices() {
        startRefreshingLayout()
        startListeningTransactions()
    }
    
    func stopAllServices() {
        stopRefreshingLayout()
        stopListeningTransactions()
        transactionsStream.discardPendingTransactions()
    }
    
    func registerAccount(account: WalletAccountModel) {
        externalStoreProxy.addAccount(account)
    }
    
    // MARK: Initialization

    init(uniqueIdentifier: String) {
        self.uniqueIdentifier = uniqueIdentifier
    
        // open store
        let storeURL = NSURL(fileURLWithPath: (ApplicationManager.sharedInstance.databasesDirectoryPath as NSString).stringByAppendingPathComponent(uniqueIdentifier + ".sqlite"))
        self.store = WalletStoreManager.managedStoreAtURL(storeURL, uniqueIdentifier: uniqueIdentifier)
        self.externalStoreProxy = WalletStoreProxy(store: store, delegateQueue: NSOperationQueue.mainQueue())
        
        // create services
        self.layoutDiscoverer = WalletLayoutDiscoverer(store: self.store, delegateQueue: NSOperationQueue.mainQueue())
        self.websocketListener = WalletWebsocketListener(delegateQueue: NSOperationQueue.mainQueue())
        self.transactionsStream = WalletTransactionsStream(store: self.store, delegateQueue: NSOperationQueue.mainQueue())
        
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

// MARK: - WalletLayoutDiscovererDelegate

extension WalletAPIManager: WalletLayoutDiscovererDelegate {
    
    func layoutDiscoverDidStart(layoutDiscoverer: WalletLayoutDiscoverer) {
        notifyObservers(WalletManagerDidStartRefreshingLayoutNotification)
    }
    
    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, didStopWithError error: WalletLayoutDiscovererError?) {
        notifyObservers(WalletManagerDidStopRefreshingLayoutNotification)
    }
    
    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void) {
        let accounts: [WalletAccountModel] = [
            WalletAccountModel(index: 0, extendedPublicKey: "xpub6Cec5KTvWeSNEw9bHe5v5sFPRwpM1x86Scuu7FuBpsQrhBg5GjhhBePAxpUQxmX8RNdAW2rfxZPQrrE5JAUqaa7MRfnXGKjQJB2awZ7Qgxy", name: nil),
            WalletAccountModel(index: 1, extendedPublicKey: "xpub6Cec5KTvWeSNG1BsXpNab628WvCGZEECqiHPY7JcBWSQgKfQN5wK4hUr3e9PM464Q7u9owCNHKTRGNGMxYdfPgUFZ3hR3ko2ap7xqxHmCxk", name: nil),
            WalletAccountModel(index: 2, extendedPublicKey: "xpub6Cec5KTvWeSNJtrFK6PqoCoP369xG8HYEDswqmTsQq63frkqF6dqYV56qRjJ7VQn1TEaejBPowG9vMGxVhsfRinhTgH5fTcAvMedABC8w6P", name: nil),
            WalletAccountModel(index: 3, extendedPublicKey: "xpub6Cec5KTvWeSNLwb2fMVRYVJn4w49WebLyg7cJM2QsbQotPggFX49H8jKvieYCMHaGCsKrW9VVknSt7KRxRuacasuGyJm74hZ4JeNRdsRB6Y", name: nil),
            WalletAccountModel(index: 4, extendedPublicKey: "xpub6Cec5KTvWeSNQLuVYmj4JZkX8q3VpSoQRd4BRkcPmhQvDaFi3yPobQXW795SLwN9zHXv9vYJyt4FrkWRBuJZMrg81qx7BDxNffPtJmFg2mb", name: nil)
        ]
        guard index < accounts.count else {
            continueBlock(false)
            return
        }
        registerAccount(accounts[index])
        continueBlock(true)
    }

    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, didDiscoverTransactions transactions: [WalletRemoteTransaction]) {
        transactionsStream.enqueueTransactions(transactions)
    }
    
}

// MARK: - WalletWebsocketListenerDelegate

extension WalletAPIManager: WalletWebsocketListenerDelegate {
    
    func websocketListenerDidStart(websocketListener: WalletWebsocketListener) {
        notifyObservers(WalletManagerDidStartListeningTransactionsNotification)
    }
    
    func websocketListenerDidStop(websocketListener: WalletWebsocketListener) {
        notifyObservers(WalletManagerDidStopListeningTransactionsNotification)
    }
    
    func websocketListener(websocketListener: WalletWebsocketListener, didReceiveTransaction transaction: WalletRemoteTransaction) {
        transactionsStream.enqueueTransactions([transaction])
    }
    
}