//
//  WalletLayoutDiscoverer.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletLayoutDiscovererDelegate: class {
    
    func layoutDiscoverer(layoutDiscoverer: WalletLayoutDiscoverer, didDiscoverTransactions transactions: [WalletRemoteTransaction])
    
}

final class WalletLayoutDiscoverer {
    
    weak var delegate: WalletLayoutDiscovererDelegate?
    private var discovering = false
    private let walletLayout: WalletLayout
    
    func startDiscovery() {
        guard !discovering else { return }
        discovering = true
    }
    
    func stopDiscovery() {
        guard discovering else { return }
        discovering = false
        
    }
    
    // MARK: Initialization
    
    init(walletLayout: WalletLayout) {
        self.walletLayout = walletLayout
    }
    
    deinit {
        stopDiscovery()
    }
    
}