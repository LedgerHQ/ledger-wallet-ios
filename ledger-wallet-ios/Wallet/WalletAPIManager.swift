//
//  WalletAPIManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

typealias WalletRemoteTransaction = [String: AnyObject]

final class WalletAPIManager {
    
    private let uniqueIdentifier: String
    private let websocketListener: WalletWebsocketListener
    private let transactionsStream: WalletTransactionsStream
    private let layoutDiscoverer: WalletLayoutDiscoverer
    private let walletLayout: WalletLayout
    private let dataProvider: WalletDataProvider
    private let logger = Logger.sharedInstance(name: "WalletAPIManager")

    // MARK: Initialization
    
    init(uniqueIdentifier: String) {
        self.uniqueIdentifier = uniqueIdentifier
    
        // open store
        let storeURL = NSURL(fileURLWithPath: (ApplicationManager.sharedInstance.databasesDirectoryPath as NSString).stringByAppendingPathComponent(uniqueIdentifier + ".sqlite"))
        let store = WalletStoreManager().manageStoreAtURL(storeURL)
        
        // create services
        dataProvider = WalletDataProvider(store: store)
        walletLayout = WalletLayout()
        websocketListener = WalletWebsocketListener()
        layoutDiscoverer = WalletLayoutDiscoverer(walletLayout: walletLayout)
        transactionsStream = WalletTransactionsStream(walletLayout: walletLayout)
    }
    
}

extension WalletAPIManager: WalletWebsocketListenerDelegate {
    
    // MARK: WalletWebsocketListenerDelegate
    
    func websocketListener(websocketListener: WalletWebsocketListener, didReceiveTransaction transaction: WalletRemoteTransaction) {
        transactionsStream.enqueueTransaction(transaction)
    }
    
}

extension WalletAPIManager: WalletLayoutDiscovererDelegate {
    
    // MARK: WalletLayoutDiscovererDelegate
    
    func layoutDiscoverer(layoutDiscoverer: WalletLayoutDiscoverer, didDiscoverTransactions transactions: [WalletRemoteTransaction]) {
        for transaction in transactions {
            transactionsStream.enqueueTransaction(transaction)
        }
    }
    
}