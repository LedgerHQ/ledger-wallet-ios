//
//  PairingKeychainItem.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

class PairingKeychainItem: KeychainItem {
    
    override class var serviceIdentifier: String { return "co.ledger.ledgerwallet.pairing" }
    private(set) var pairingkey: String!

    override func initialize() -> Bool {
        return true
    }
    
}