//
//  WalletAddressEntity.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletAddressEntity: SQLiteEntityType {
    
    static let tableName = "address"
    
    static let addressKey = "address"
    static let accountIndexKey = "account_index"
    static let chainIndexKey = "chain_index"
    static let keyIndexKey = "key_index"
    static let relativePathKey = "relative_path"
    
    static let allFieldKeys = [
        addressKey,
        accountIndexKey,
        chainIndexKey,
        keyIndexKey,
        relativePathKey
    ]
    
}