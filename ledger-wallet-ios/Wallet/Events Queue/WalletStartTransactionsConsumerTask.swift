//
//  WalletStartTransactionsConsumerTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletStartTransactionsConsumerTask: WalletTaskType {
    
    private let transactionsConsumer: WalletTransactionsConsumer
    
    func process(completionQueue: NSOperationQueue, completion: () -> Void) {
        transactionsConsumer.startRefreshing()
        completion()
    }
    
    // MARK: Initialization
    
    init(transactionsConsumer: WalletTransactionsConsumer) {
        self.transactionsConsumer = transactionsConsumer
    }
    
}