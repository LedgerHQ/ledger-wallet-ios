//
//  WalletAddress.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletAddress {
    
    let address: String
    let path: WalletAddressPath
    
    // MARK: Initialization
    
    init(address: String, path: WalletAddressPath) {
        self.path = path
        self.address = address
    }
    
}

// MARK: - SQLiteFetchableModel

extension WalletAddress: SQLiteFetchableModel {
    
    init?(resultSet: SQLiteStoreResultSet) {
        guard let
            accountIndex = self.dynamicType.optionalIntegerForKey(WalletAddressEntity.accountIndexKey, resultSet: resultSet),
            chainIndex = self.dynamicType.optionalIntegerForKey(WalletAddressEntity.chainIndexKey, resultSet: resultSet),
            keyIndex = self.dynamicType.optionalIntegerForKey(WalletAddressEntity.keyIndexKey, resultSet: resultSet),
            address = self.dynamicType.optionalStringForKey(WalletAddressEntity.addressKey, resultSet: resultSet)
        else {
            return nil
        }
        
        self.address = address
        self.path = WalletAddressPath(accountIndex: accountIndex, chainIndex: chainIndex, keyIndex: keyIndex)
    }
    
}