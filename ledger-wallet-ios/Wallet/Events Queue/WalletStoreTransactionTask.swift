//
//  WalletStoreTransactionTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletStoreTransactionTask: WalletTaskType {
    
    private let transaction: WalletTransactionContainer
    private let transactionsStream: WalletTransactionsStream
    
    func process(completionQueue: NSOperationQueue, completion: () -> Void) {
        transactionsStream.processTransaction(transaction, completionQueue: completionQueue, completion: completion)
    }
    
    // MARK: Initialization
    
    init(transaction: WalletTransactionContainer, transactionsStream: WalletTransactionsStream) {
        self.transaction = transaction
        self.transactionsStream = transactionsStream
    }
    
}