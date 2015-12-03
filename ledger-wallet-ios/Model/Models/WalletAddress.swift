//
//  WalletAddress.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletAddress: SQLiteFetchableModel {
    
    let accountIndex: Int
    let chainIndex: Int
    let keyIndex: Int
    let address: String
    
    init?(resultSet: FMResultSet) {
        accountIndex = self.dynamicType.integerForKey(AccountEntity.indexKey, resultSet: resultSet)!
        chainIndex = self.dynamicType.integerForKey(AccountEntity.indexKey, resultSet: resultSet)!
        keyIndex = self.dynamicType.integerForKey(AccountEntity.indexKey, resultSet: resultSet)!
        address = self.dynamicType.stringForKey(AccountEntity.indexKey, resultSet: resultSet)!
    }
    
}