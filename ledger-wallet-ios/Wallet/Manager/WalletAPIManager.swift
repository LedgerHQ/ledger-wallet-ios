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
        layoutDiscoverer.delegate = self
    }
    
    deinit {
        layoutDiscoverer.stopDiscovery()
    }
    
}

extension WalletAPIManager: WalletLayoutDiscovererDelegate {
    
    // MARK: WalletLayoutDiscovererDelegate

    func layoutDiscoverDidStart(layoutDiscoverer: WalletLayoutDiscoverer) {

    }
    
    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, didStopWithError error: WalletLayoutDiscovererError?) {

    }
    
    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, extendedPublicKeyAtIndex index: Int, providerBlock: (String?) -> Void) {
        let xpubs: [Int: String] = [
            0: "xpub6Cec5KTvWeSNEw9bHe5v5sFPRwpM1x86Scuu7FuBpsQrhBg5GjhhBePAxpUQxmX8RNdAW2rfxZPQrrE5JAUqaa7MRfnXGKjQJB2awZ7Qgxy",
            1: "xpub6Cec5KTvWeSNG1BsXpNab628WvCGZEECqiHPY7JcBWSQgKfQN5wK4hUr3e9PM464Q7u9owCNHKTRGNGMxYdfPgUFZ3hR3ko2ap7xqxHmCxk",
            2: "xpub6Cec5KTvWeSNJtrFK6PqoCoP369xG8HYEDswqmTsQq63frkqF6dqYV56qRjJ7VQn1TEaejBPowG9vMGxVhsfRinhTgH5fTcAvMedABC8w6P",
            3: "xpub6Cec5KTvWeSNLwb2fMVRYVJn4w49WebLyg7cJM2QsbQotPggFX49H8jKvieYCMHaGCsKrW9VVknSt7KRxRuacasuGyJm74hZ4JeNRdsRB6Y",
            4: "xpub6Cec5KTvWeSNQLuVYmj4JZkX8q3VpSoQRd4BRkcPmhQvDaFi3yPobQXW795SLwN9zHXv9vYJyt4FrkWRBuJZMrg81qx7BDxNffPtJmFg2mb"
        ]
        guard let xpub = xpubs[index] else {
            providerBlock(nil)
            return
        }
        providerBlock(xpub)
    }

    func layoutDiscover(layoutDiscoverer: WalletLayoutDiscoverer, didDiscoverTransactions transactions: [WalletRemoteTransaction]) {
        print("DID DISCOVER \(transactions.count)")
    }
    
}