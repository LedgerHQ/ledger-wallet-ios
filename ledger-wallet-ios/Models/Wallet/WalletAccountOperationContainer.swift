//
//  WalletAccountOperationContainer.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletAccountOperationContainer {
    
    let account: WalletAccount
    let operationContainer: WalletOperationContainer
    
    // MARK: Initialization
    
    init(account: WalletAccount, operationContainer: WalletOperationContainer) {
        self.account = account
        self.operationContainer = operationContainer
    }
    
}