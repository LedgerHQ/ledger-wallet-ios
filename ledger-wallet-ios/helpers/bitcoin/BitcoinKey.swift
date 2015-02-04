//
//  BitcoinKey.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

struct BitcoinKey {
    
    let publicKey: NSData
    let privateKey: NSData

    init() {
        let key = BTCKey()
        publicKey = key.publicKey
        privateKey = key.privateKey
    }
    
    // MARK: Key agreement
    
    func keyAgreementWithPublicKey(publicKey: NSData) -> NSData {
        return NSData()
    }
    
}