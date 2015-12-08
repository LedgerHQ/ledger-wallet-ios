//
//  WalletAccount.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletAccount: SQLiteFetchableModel {
    
    let index: Int
    let extendedPublicKey: String
    let nextInternalIndex: Int
    let nextExternalIndex: Int
    let name: String?
    
    // MARK: Initialization
    
    init?(resultSet: SQLiteStoreResultSet) {
        index = self.dynamicType.integerForKey(AccountEntity.indexKey, resultSet: resultSet)!
        extendedPublicKey = self.dynamicType.stringForKey(AccountEntity.extendedPublicKeyKey, resultSet: resultSet)!
        nextInternalIndex = self.dynamicType.integerForKey(AccountEntity.nextInternalIndexKey, resultSet: resultSet)!
        nextExternalIndex = self.dynamicType.integerForKey(AccountEntity.nextExternalIndexKey, resultSet: resultSet)!
        name = self.dynamicType.stringForKey(AccountEntity.nameKey, resultSet: resultSet)
    }
    
}