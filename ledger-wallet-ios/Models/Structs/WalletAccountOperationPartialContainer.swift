//
//  WalletAccountOperationPartialContainer.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 20/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletAccountOperationPartialContainer {
    
    let transaction: WalletTransaction
    let operation: WalletOperation
    let block: WalletBlock?
    let account: WalletAccount
    
}

// MARK: - SQLiteFetchableModel

extension WalletAccountOperationPartialContainer: SQLiteFetchableModel {
    
    init?(resultSet: SQLiteStoreResultSet) {
        guard let
            account = WalletAccount(resultSet: resultSet),
            operation = WalletOperation(resultSet: resultSet),
            transaction = WalletTransaction(resultSet: resultSet)
        else {
            return nil
        }
        
        self.transaction = transaction
        self.operation = operation
        self.account = account
        self.block = WalletBlock(resultSet: resultSet)
    }
    
}