//
//  WalletOperationTableEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletOperationTableEntity: SQLiteTableEntity {
    
    static let tableName = "operation"
    
    static let accountIndexKey = "account_index"
    
}