//
//  WalletTransactionInputEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletTransactionInputEntity: SQLiteEntityType {
    
    static let tableName = "transaction_input"
    
    static let uidKey = "uid"
    static let outputHashKey = "output_hash"
    static let outputIndexKey = "output_index"
    static let valueKey = "value"
    static let scriptSignatureKey = "script_signature"
    static let addressKey = "address"
    static let coinbaseKey = "coinbase"
    static let transactionHashKey = "transaction_hash"
    static let indexKey = "index"
 
    static let allFieldKeys =  [
        uidKey,
        outputHashKey,
        outputIndexKey,
        valueKey,
        scriptSignatureKey,
        addressKey,
        coinbaseKey,
        indexKey,
        transactionHashKey
    ]
    
}