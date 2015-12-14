//
//  WalletAccount.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletAccountModel {
    
    let index: Int
    let extendedPublicKey: String
    let nextInternalIndex: Int
    let nextExternalIndex: Int
    let name: String?
    
    // MARK: Initialization
    
    init(index: Int, extendedPublicKey: String, name: String?) {
        self.init(index: index, extendedPublicKey: extendedPublicKey, nextInternalIndex: 0, nextExternalIndex: 0, name: name)
    }
    
    init(index: Int, extendedPublicKey: String, nextInternalIndex: Int, nextExternalIndex: Int, name: String?) {
        self.index = index
        self.extendedPublicKey = extendedPublicKey
        self.name = name
        self.nextExternalIndex = nextExternalIndex
        self.nextInternalIndex = nextInternalIndex
    }
    
}

// MARK: - SQLiteFetchableModel

extension WalletAccountModel: SQLiteFetchableModel {
        
    init?(resultSet: SQLiteStoreResultSet) {
        guard let
            index = self.dynamicType.optionalIntegerForKey(WalletAccountTableEntity.indexKey, resultSet: resultSet),
            extendedPublicKey = self.dynamicType.optionalStringForKey(WalletAccountTableEntity.extendedPublicKeyKey, resultSet: resultSet),
            nextInternalIndex = self.dynamicType.optionalIntegerForKey(WalletAccountTableEntity.nextInternalIndexKey, resultSet: resultSet),
            nextExternalIndex = self.dynamicType.optionalIntegerForKey(WalletAccountTableEntity.nextExternalIndexKey, resultSet: resultSet)
        else {
            return nil
        }
        
        self.index = index
        self.extendedPublicKey = extendedPublicKey
        self.nextInternalIndex = nextInternalIndex
        self.nextExternalIndex = nextExternalIndex
        self.name = self.dynamicType.optionalStringForKey(WalletAccountTableEntity.nameKey, resultSet: resultSet)
    }
    
}