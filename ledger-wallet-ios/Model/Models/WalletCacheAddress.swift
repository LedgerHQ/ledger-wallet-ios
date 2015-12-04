//
//  WalletCacheAddress.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletCacheAddress: SQLiteFetchableModel {
    
    let addressPath: WalletAddressPath
    let address: String
    var accountIndex: Int { return addressPath.accountIndex }
    var chainIndex: Int { return addressPath.chainIndex }
    var keyIndex: Int { return addressPath.keyIndex }
    
    init?(resultSet: FMResultSet) {
        let accountIndex = self.dynamicType.integerForKey(AddressEntity.accountIndexKey, resultSet: resultSet)!
        let chainIndex = self.dynamicType.integerForKey(AddressEntity.chainIndexKey, resultSet: resultSet)!
        let keyIndex = self.dynamicType.integerForKey(AddressEntity.keyIndexKey, resultSet: resultSet)!
        addressPath = WalletAddressPath(accountIndex: accountIndex, chainIndex: chainIndex, keyIndex: keyIndex)
        address = self.dynamicType.stringForKey(AddressEntity.addressKey, resultSet: resultSet)!
    }
    
    init(addressPath: WalletAddressPath, address: String) {
        self.addressPath = addressPath
        self.address = address
    }
    
}