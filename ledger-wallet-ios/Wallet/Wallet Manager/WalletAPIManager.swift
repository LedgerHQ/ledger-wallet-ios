//
//  WalletAPIManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

typealias WalletRemoteTransaction = [String: AnyObject]

final class WalletAPIManager: BaseWalletManager {
    
    let uniqueIdentifier: String
    var isRefreshingLayout: Bool { return layoutDiscoverer.isDiscovering }
    
    private let layoutDiscoverer: WalletLayoutDiscoverer
    private let websocketListener: WalletWebsocketListener
    private let transactionsStream: WalletTransactionsStream
    private let storeProxy: WalletStoreProxy
    private let store: SQLiteStore
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
    }
    
    // MARK: Initialization

    init(uniqueIdentifier: String) {
        self.uniqueIdentifier = uniqueIdentifier
    
        // open store
        let storeURL = NSURL(fileURLWithPath: (ApplicationManager.sharedInstance.databasesDirectoryPath as NSString).stringByAppendingPathComponent(uniqueIdentifier + ".sqlite"))
        self.store = WalletStoreManager.managedStoreAtURL(storeURL, uniqueIdentifier: uniqueIdentifier)
        self.storeProxy = WalletStoreProxy(store: self.store, delegateQueue: NSOperationQueue.mainQueue())
        
        // create services
        self.layoutDiscoverer = WalletLayoutDiscoverer(store: self.store, delegateQueue: NSOperationQueue.mainQueue())
        self.transactionsStream = WalletTransactionsStream(storeProxy: storeProxy)
        self.websocketListener = WalletWebsocketListener()
        
        startAllServices()
    }
    
    deinit {
        stopAllServices()
        store.close()
    }
    
}

extension WalletAPIManager: WalletLayoutDiscovererDelegate {
    
    // MARK: WalletLayoutDiscovererDelegate

    func layoutDiscoverDidStart(layoutDiscoverer: WalletLayoutDiscoverer) {
        // notify
        notifyObservers(WalletManagerDidStartRefreshingLayoutNotification)
    }
    
    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, didStopWithError error: WalletLayoutDiscovererError?) {
        // notify
        notifyObservers(WalletManagerDidStopRefreshingLayoutNotification)
    }
    
    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, accountAtIndex index: Int, providerBlock: (WalletAccountModel?) -> Void) {
        let accounts: [WalletAccountModel] = [
            WalletAccountModel(index: 0, extendedPublicKey: "xpub6Cec5KTvWeSNEw9bHe5v5sFPRwpM1x86Scuu7FuBpsQrhBg5GjhhBePAxpUQxmX8RNdAW2rfxZPQrrE5JAUqaa7MRfnXGKjQJB2awZ7Qgxy", name: nil),
            WalletAccountModel(index: 1, extendedPublicKey: "xpub6Cec5KTvWeSNG1BsXpNab628WvCGZEECqiHPY7JcBWSQgKfQN5wK4hUr3e9PM464Q7u9owCNHKTRGNGMxYdfPgUFZ3hR3ko2ap7xqxHmCxk", name: nil),
            WalletAccountModel(index: 2, extendedPublicKey: "xpub6Cec5KTvWeSNJtrFK6PqoCoP369xG8HYEDswqmTsQq63frkqF6dqYV56qRjJ7VQn1TEaejBPowG9vMGxVhsfRinhTgH5fTcAvMedABC8w6P", name: nil),
            WalletAccountModel(index: 3, extendedPublicKey: "xpub6Cec5KTvWeSNLwb2fMVRYVJn4w49WebLyg7cJM2QsbQotPggFX49H8jKvieYCMHaGCsKrW9VVknSt7KRxRuacasuGyJm74hZ4JeNRdsRB6Y", name: nil),
            WalletAccountModel(index: 4, extendedPublicKey: "xpub6Cec5KTvWeSNQLuVYmj4JZkX8q3VpSoQRd4BRkcPmhQvDaFi3yPobQXW795SLwN9zHXv9vYJyt4FrkWRBuJZMrg81qx7BDxNffPtJmFg2mb", name: nil)
        ]
        guard index < accounts.count else {
            providerBlock(nil)
            return
        }
        providerBlock(accounts[index])
    }

    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, didDiscoverTransactions transactions: [WalletRemoteTransaction]) {
        // enqueue transactions
        transactionsStream.enqueueTransactions(transactions)
    }
    
}

extension WalletAPIManager: WalletWebsocketListenerDelegate {
    
    // MARK: WalletWebsocketListenerDelegate
    
    func websocketListener(websocketListener: WalletWebsocketListener, didReceiveTransaction transaction: WalletRemoteTransaction) {
        // enqueue transaction
        transactionsStream.enqueueTransactions([transaction])
    }
    
}

extension WalletAPIManager {
    
    // MARK: Notifications management
    
    private func notifyObservers(notification: String, userInfo: [String: AnyObject]? = nil) {
        delegateQueue.addOperationWithBlock() {
            NSNotificationCenter.defaultCenter().postNotificationName(notification, object: self, userInfo: userInfo)
        }
    }
    
}