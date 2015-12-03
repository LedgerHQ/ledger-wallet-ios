//
//  WalletLayoutDiscoverer.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletLayoutDiscovererDelegate: class {
    
    func layoutDiscoverer(layoutDiscoverer: WalletLayoutDiscoverer, didFinishDiscoveryAtAccountIndex: Int)
    
}

final class WalletLayoutDiscoverer {
    
    weak var delegate: WalletLayoutDiscovererDelegate?
    private var discoveringLayout = false
    private let storeProxy: WalletStoreProxy
    private var accounts: [WalletDiscoverableAccount] = []
    private var currentAccountIndex = 0
    private var currentChainIndex = 0
    private var currentKeyIndex = 0
    
    // NOTE: 44'/0'/0'/account/chain/key
    
    // MARK: Layout discovery
    
    func startDiscovery() {
        guard !discoveringLayout else {
            return
        }
        discoveringLayout = true
        accounts = []
        currentAccountIndex = 0
        currentChainIndex = 0
        currentKeyIndex = 0
    }
    
    private func queryTransactionsForAccountIndex(accountIndex: Int, chainIndex: Int, keyIndex: Int) {
        guard accounts.count > accountIndex else {
            // pas assez de comptes
            return
        }
        let account = accounts[accountIndex]
        guard let extendedPublicKey = account.extendedPublicKey else {
            // pas de xpub
            return
        }
        
    }
    
    func stopDiscovery() {
        guard discoveringLayout else {
            return
        }
        discoveringLayout = false
    }
    
    // MARK: Initialization
    
    init(storeProxy: WalletStoreProxy) {
        self.storeProxy = storeProxy
    }
    
}