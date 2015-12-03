//
//  AddressEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct AddressEntity: SQLiteStorableEntity {
    
    static let tableName = "address"
    
    static let addressKey = "address"
    static let accountIndexKey = "account_index"
    static let chainIndexKey = "chain_index"
    static let keyIndexKey = "key_index"
    
}