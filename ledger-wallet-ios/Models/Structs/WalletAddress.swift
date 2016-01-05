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
            accountIndex = resultSet.integerForKey(WalletAddressEntity.accountIndexKey),
            chainIndex = resultSet.integerForKey(WalletAddressEntity.chainIndexKey),
            keyIndex = resultSet.integerForKey(WalletAddressEntity.keyIndexKey),
            address = resultSet.stringForKey(WalletAddressEntity.addressKey)
        else {
            return nil
        }
        
        self.address = address
        self.path = WalletAddressPath(accountIndex: accountIndex, chainIndex: chainIndex, keyIndex: keyIndex)
    }
    
}