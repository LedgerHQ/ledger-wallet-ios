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
    let relativePath: String
    let path: WalletAddressPath
    
    // MARK: Initialization
    
    init(address: String, path: WalletAddressPath, relativePath: String) {
        self.path = path
        self.address = address
        self.relativePath = relativePath
    }
    
}

// MARK: - SQLiteFetchableModel

extension WalletAddress: SQLiteFetchableModel {
    
    init?(resultSet: SQLiteStoreResultSet) {
        guard let
            accountIndex = resultSet.integerForKey(WalletAddressEntity.fieldKeypathWithKey(WalletAddressEntity.accountIndexKey)),
            chainIndex = resultSet.integerForKey(WalletAddressEntity.fieldKeypathWithKey(WalletAddressEntity.chainIndexKey)),
            keyIndex = resultSet.integerForKey(WalletAddressEntity.fieldKeypathWithKey(WalletAddressEntity.keyIndexKey)),
            address = resultSet.stringForKey(WalletAddressEntity.fieldKeypathWithKey(WalletAddressEntity.addressKey)),
            relativePath = resultSet.stringForKey(WalletAddressEntity.fieldKeypathWithKey(WalletAddressEntity.relativePathKey))
        else {
            return nil
        }
        
        self.address = address
        self.path = WalletAddressPath(BIP32AccountIndex: accountIndex, chainIndex: chainIndex, keyIndex: keyIndex)
        self.relativePath = relativePath
    }
    
}