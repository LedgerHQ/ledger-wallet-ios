//
//  WalletOperationContainer.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletOperationContainer {
    
    let operation: WalletOperation
    let transactionContainer: WalletTransactionContainer
    
    // MARK: Initialization
    
    init(operation: WalletOperation, transactionContainer: WalletTransactionContainer) {
        self.operation = operation
        self.transactionContainer = transactionContainer
    }
    
}