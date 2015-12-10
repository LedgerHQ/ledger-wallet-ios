//
//  WalletTransactionsStream.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsStream {
    
    private let storeProxy: WalletStoreProxy
    
    // MARK: Transactions management
    
    func enqueueTransactions(transactions: [WalletRemoteTransaction]) {
        
    }
    
    // MARK: Initialization
    
    init(store: SQLiteStore) {
        self.storeProxy = WalletStoreProxy(store: store, delegateQueue: NSOperationQueue.mainQueue())
    }
    
}