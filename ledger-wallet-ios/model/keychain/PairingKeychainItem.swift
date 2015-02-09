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
    override class var itemClass: String { return kSecClassGenericPassword }
    private(set) var pairingKey: Crypto.Key!
    private(set) var pairingId: String!
    private(set) var dongleName: String!

    override func initialize(attributes: [String: AnyObject], data: NSData) -> Bool {
        if let JSON = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: nil) as? [String: AnyObject] {
            if let pairingKey = JSON["pairing_key"] as? String {
                self.pairingKey = Crypto.Key(symmetricKey: Crypto.Encode.dataFromBase16String(pairingKey))
            }
            pairingId = JSON["pairing_id"] as? String
            dongleName = JSON["dongle_name"] as? String
        }
        return (pairingKey != nil && pairingId != nil && dongleName != nil)
    }
    
}