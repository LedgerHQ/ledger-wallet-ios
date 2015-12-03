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
    private let layoutDiscoverer: WalletLayoutDiscoverer
    private let storeProxy: WalletStoreProxy
    private let logger = Logger.sharedInstance(name: "WalletAPIManager")
    
    func lookForNewTransactions() {
        layoutDiscoverer.startDiscovery()
    }
    
    // MARK: Initialization

    init(uniqueIdentifier: String) {
        self.uniqueIdentifier = uniqueIdentifier
    
        // open store
        let storeURL = NSURL(fileURLWithPath: (ApplicationManager.sharedInstance.databasesDirectoryPath as NSString).stringByAppendingPathComponent(uniqueIdentifier + ".sqlite"))
        storeProxy = WalletStoreManager().storeProxyAtURL(storeURL, withUniqueIdentifier: uniqueIdentifier)
        
        // create services
        layoutDiscoverer = WalletLayoutDiscoverer(storeProxy: storeProxy)
    }
    
    deinit {
        layoutDiscoverer.stopDiscovery()
    }
    
}