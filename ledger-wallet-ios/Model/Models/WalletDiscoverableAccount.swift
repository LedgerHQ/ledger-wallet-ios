//
//  WalletDiscoverableAccount.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletDiscoverableAccount: SQLiteFetchableModel {
    
    let index: Int
    let extendedPublicKey: String
    
    // MARK: Initialization
    
    init?(resultSet: FMResultSet) {
        index = self.dynamicType.integerForKey(AccountEntity.indexKey, resultSet: resultSet)!
        extendedPublicKey = self.dynamicType.stringForKey(AccountEntity.extendedPublicKeyKey, resultSet: resultSet)!
    }
    
}