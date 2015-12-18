//
//  WalletOperationTableEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletOperationTableEntity: SQLiteTableEntityType {
    
    static let tableName = "operation"
    
    static let uidKey = "uid"
    static let amountKey = "amount"
    static let kindKey = "kind"
    static let transactionHashKey = "transaction_hash"
    static let accountIndexKey = "account_index"
    
}