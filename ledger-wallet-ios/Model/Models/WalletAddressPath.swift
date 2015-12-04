//
//  WalletAddressPath.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 03/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletAddressPath {
    let accountIndex: Int
    let chainIndex: Int
    let keyIndex: Int
    
    var relativePath: String {
        return "/\(accountIndex)'" + chainPath
    }
    
    var chainPath: String {
        return "/\(chainIndex)/\(keyIndex)"
    }
    
    var BIP44Path: String {
        return "/44'/0'" + relativePath
    }
}

extension WalletAddressPath: Equatable {}
func ==(lhs: WalletAddressPath, rhs: WalletAddressPath) -> Bool {
    return lhs.accountIndex == rhs.accountIndex && lhs.chainIndex == rhs.chainIndex && lhs.keyIndex == rhs.keyIndex
}