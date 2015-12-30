//
//  WalletAccountEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletAccountEntity: SQLiteEntityType {
 
    static let tableName = "account"
    
    static let indexKey = "index"
    static let nameKey = "name"
    static let extendedPublicKeyKey = "extended_public_key"
    static let nextExternalIndexKey = "next_external_index"
    static let nextInternalIndexKey = "next_internal_index"
    static let balanceKey = "balance"
    static let hiddenKey = "hidden"
    
}