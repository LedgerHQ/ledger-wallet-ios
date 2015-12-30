//
//  WalletTransactionOutputEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletTransactionOutputEntity: SQLiteEntityType {
    
    static let tableName = "transaction_output"
    
    static let scriptHexKey = "script_hex"
    static let valueKey = "value"
    static let addressKey = "address"
    static let indexKey = "index"
    static let transactionHashKey = "transaction_hash"
    
}