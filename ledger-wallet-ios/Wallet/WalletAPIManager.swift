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
    
    private let websocketListener: WalletWebsocketListener
    private let transactionsStream: WalletTransactionsStream
    private let layoutDiscoverer: WalletLayoutDiscoverer
    private let walletLayout: WalletLayout
    
    // MARK: Wallet management
    
    private func openWallet() {
        // launch services
        websocketListener.delegate = self
        websocketListener.startListening()
        layoutDiscoverer.delegate = self
        layoutDiscoverer.startDiscovery()
    }
    
    private func closeWallet() {
        // stop services
        websocketListener.stopListening()
        layoutDiscoverer.stopDiscovery()
    }
    
    // MARK: Initialization
    
    init(coreDataStack: CoreDataStack) {
        // create services
        walletLayout = WalletLayout()
        websocketListener = WalletWebsocketListener()
        layoutDiscoverer = WalletLayoutDiscoverer(walletLayout: walletLayout)
        transactionsStream = WalletTransactionsStream(walletLayout: walletLayout)
        
        openWallet()
    }
    
    deinit {
        closeWallet()
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