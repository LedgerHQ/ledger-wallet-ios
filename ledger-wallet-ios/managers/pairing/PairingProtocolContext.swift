//
//  PairingProtocolContext.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class PairingProtocolContext {
    
    var pairingId: String! = nil
    var pairingKey: Crypto.Key! = nil
    var sessionKey: Crypto.Key! = nil
    var nonce: NSData! = nil
    
    let internalKey: Crypto.Key
    let attestationKey: Crypto.Key
    
    // MARK: - Keychain item management
    
    class func canCreatePairingKeychainItemNamed(name: String) -> Bool {
        // check if this name already exists
        let allItems = PairingKeychainItem.fetchAll() as! [PairingKeychainItem]
        for item in allItems {
            if item.dongleName == name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
                return false
            }
        }
        return true
    }
    
    func createPairingKeychainItemNamed(name: String) -> Bool {
        // check data integrity
        if (pairingId == nil || pairingKey == nil) {
            return false
        }
        
        let pairingKeychainItem = PairingKeychainItem.create()
        pairingKeychainItem.pairingKey = pairingKey
        pairingKeychainItem.pairingId = pairingId
        pairingKeychainItem.dongleName = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        return true
    }
    
    // MARK: - Initialization
    
    init(internalKey: Crypto.Key, attestationKey: Crypto.Key) {
        self.internalKey = internalKey
        self.attestationKey = attestationKey
    }
    
    convenience init() {
        self.init(internalKey: Crypto.Key(), attestationKey: Crypto.Key(symmetricKey: LedgerDongleAttestationKeyData))
    }
    
}