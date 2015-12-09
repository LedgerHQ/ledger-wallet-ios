//
//  WalletAddress.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletAddressModel {
    
    let address: String
    var accountIndex: Int { return addressPath.accountIndex }
    var chainIndex: Int { return addressPath.chainIndex }
    var keyIndex: Int { return addressPath.keyIndex }
    let addressPath: WalletAddressPath
    
    // MARK: Initialization
    
    init(addressPath: WalletAddressPath, address: String) {
        self.addressPath = addressPath
        self.address = address
    }
    
}

// MARK: - SQLiteFetchableModel

extension WalletAddressModel: SQLiteFetchableModel {
    
    init?(resultSet: SQLiteStoreResultSet) {
        let accountIndex = self.dynamicType.optionalIntegerForKey(WalletAddressTableEntity.accountIndexKey, resultSet: resultSet)!
        let chainIndex = self.dynamicType.optionalIntegerForKey(WalletAddressTableEntity.chainIndexKey, resultSet: resultSet)!
        let keyIndex = self.dynamicType.optionalIntegerForKey(WalletAddressTableEntity.keyIndexKey, resultSet: resultSet)!
        addressPath = WalletAddressPath(accountIndex: accountIndex, chainIndex: chainIndex, keyIndex: keyIndex)
        address = self.dynamicType.optionalStringForKey(WalletAddressTableEntity.addressKey, resultSet: resultSet)!
    }
    
}