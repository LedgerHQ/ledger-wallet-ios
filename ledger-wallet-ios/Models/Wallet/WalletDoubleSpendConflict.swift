//
//  WalletDoubleSpendConflict.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 05/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletDoubleSpendConflict {
    
    let leftTransactionHash: String
    let rightTransactionHash: String
    
}

// MARK: - SQLiteFetchableModel

extension WalletDoubleSpendConflict: SQLiteFetchableModel {
    
    init?(resultSet: SQLiteStoreResultSet) {
        guard let
            leftTransactionHash = resultSet.stringForKey(WalletDoubleSpendConflictEntity.fieldKeypathWithKey(WalletDoubleSpendConflictEntity.leftTransactionHashKey)),
            rightTransactionHash = resultSet.stringForKey(WalletDoubleSpendConflictEntity.fieldKeypathWithKey(WalletDoubleSpendConflictEntity.rightTransactionHashKey))
        else {
            return nil
        }
        
        self.leftTransactionHash = leftTransactionHash
        self.rightTransactionHash = rightTransactionHash
    }
    
}