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
    
    let internalKey: Crypto.Key! = nil
    let attestationKey: Crypto.Key! = nil
    
    // MARK: Keychain item management
    
    func canCreatePairingItemNamed(name: String) -> Bool {
        // check data integrity
        if (pairingId == nil || pairingKey == nil) {
            return false
        }
        
        // check if this name already exists
        let allItems = PairingKeychainItem.fetchAll() as [PairingKeychainItem]
        for item in allItems {
            if item.dongleName == name {
                return false
            }
        }
        return true
    }
    
    func createNewPairingItemNamed(name: String) -> Bool {
        if (canCreatePairingItemNamed(name) == false) {
            return false
        }
        
        // TODO:
        return true
    }
    
    // MARK: Initialization
    
    init(internalKey: Crypto.Key, attestationKey: Crypto.Key) {
        self.internalKey = internalKey
        self.attestationKey = attestationKey
    }
    
    convenience init() {
        self.init(internalKey: Crypto.Key(), attestationKey: Crypto.Key(symmetricKey: LedgerDongleAttestationKeyData))
    }
    
}