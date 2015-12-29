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
    
    var isExternal: Bool { return chainIndex == 0 }
    var isInternal: Bool { return chainIndex == 1 }
    
    var relativePath: String {
        return "/\(accountIndex)'" + chainPath
    }
    
    var chainPath: String {
        return "/\(chainIndex)/\(keyIndex)"
    }
    
    var BIP44Path: String {
        return "/44'/0'" + relativePath
    }
    
    func rangeStringToKeyIndex(keyIndex: Int) -> String {
        return "\(relativePath)-\(keyIndex)"
    }
    
    func pathWithAcccountIndex(index: Int) -> WalletAddressPath {
        return WalletAddressPath(accountIndex: index, chainIndex: chainIndex, keyIndex: keyIndex)
    }
    
    func pathWithChainIndex(index: Int) -> WalletAddressPath {
        return WalletAddressPath(accountIndex: accountIndex, chainIndex: index, keyIndex: keyIndex)
    }
    
    func pathWithKeyIndex(index: Int) -> WalletAddressPath {
        return WalletAddressPath(accountIndex: accountIndex, chainIndex: chainIndex, keyIndex: index)
    }
    
    func pathWithNewAccountIndex(index: Int) -> WalletAddressPath {
        return WalletAddressPath(accountIndex: index, chainIndex: 0, keyIndex: 0)
    }
    
    func pathWithNewChainIndex(index: Int) -> WalletAddressPath {
        return WalletAddressPath(accountIndex: accountIndex, chainIndex: index, keyIndex: 0)
    }
    
    func pathWithNewKeyIndex(index: Int) -> WalletAddressPath {
        return WalletAddressPath(accountIndex: accountIndex, chainIndex: chainIndex, keyIndex: index)
    }

    // MARK: Initialization

    init(accountIndex: Int, chainIndex: Int, keyIndex: Int) {
        self.accountIndex = accountIndex
        self.chainIndex = chainIndex
        self.keyIndex = keyIndex
    }
    
    init() {
        self.init(accountIndex: 0, chainIndex: 0, keyIndex: 0)
    }
}

// MARK: - Equatable

extension WalletAddressPath: Equatable {}

func ==(lhs: WalletAddressPath, rhs: WalletAddressPath) -> Bool {
    return lhs.accountIndex == rhs.accountIndex && lhs.chainIndex == rhs.chainIndex && lhs.keyIndex == rhs.keyIndex
}