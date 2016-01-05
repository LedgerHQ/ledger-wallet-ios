//
//  WalletDoubleSpendConflictEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 05/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletDoubleSpendConflictEntity: SQLiteEntityType {
    
    static let tableName = "double_spend_conflict"
    
    static let leftTransactionHashKey = "left_transaction_hash"
    static let rightTransactionHashKey = "right_transaction_hash"
    static let leftScoreKey = "left_score"
    
}