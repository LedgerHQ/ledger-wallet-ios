//
//  WalletTransactionsStream.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsStream {
    
    private let walletLayout: WalletLayout
    
    func enqueueTransaction(transaction: WalletRemoteTransaction) {
        print("Enqueued transaction! \(transaction["hash"]!)")
    }
    
    // MARK: Initialization
    
    init(walletLayout: WalletLayout) {
        self.walletLayout = walletLayout
        
    }
    
}