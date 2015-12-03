//
//  OperationEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct OperationEntity: SQLiteStorableEntity {
    
    static let tableName = "operation"
    
    static let accountIndexKey = "account_index"
    
}