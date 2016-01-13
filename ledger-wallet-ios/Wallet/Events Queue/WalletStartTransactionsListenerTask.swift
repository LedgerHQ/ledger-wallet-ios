//
//  WalletStartTransactionsListenerTask.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletStartTransactionsListenerTask: WalletTaskType {
    
    private let transactionsListener: WalletTransactionsListener
    
    func process(completionQueue: NSOperationQueue, completion: () -> Void) {
        transactionsListener.startListening()
        completion()
    }
    
    // MARK: Initialization
    
    init(transactionsListener: WalletTransactionsListener) {
        self.transactionsListener = transactionsListener
    }
    
}