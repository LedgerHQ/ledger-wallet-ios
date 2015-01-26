//
//  PairingKeychainItem.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class PairingKeychainItem: KeychainItem {
    
    override class var serviceIdentifier: String { return "co.ledger.ledgerwallet.pairing" }
    private(set) var pairingKey: String!

    override func initialize(data: NSData) -> Bool {
        if let JSON = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: nil) as? [String: AnyObject] {
            
        }
        return false
    }
    
}