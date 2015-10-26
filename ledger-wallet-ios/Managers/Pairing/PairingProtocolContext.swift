//
//  PairingProtocolContext.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 06/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class PairingProtocolContext {
    
    var pairingId: String! = nil
    var pairingKey: NSData! = nil
    var sessionKey: NSData! = nil
    var nonce: NSData! = nil
    
    let internalKey: BTCKey
    let externalKey: BTCKey
    
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
    
    func createPairingKeychainItemNamed(name: String) -> PairingKeychainItem? {
        // check data integrity
        if (pairingId == nil || pairingKey == nil) {
            return nil
        }
        
        guard let pairingKeychainItem = PairingKeychainItem() else {
            return nil
        }
        pairingKeychainItem.beginBatchUpdate()
        pairingKeychainItem.pairingKey = pairingKey
        pairingKeychainItem.pairingId = pairingId
        pairingKeychainItem.dongleName = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        pairingKeychainItem.endBatchUpdate()
        return pairingKeychainItem
    }
    
    // MARK: - Initialization
    
    init(internalKey: BTCKey, externalKey: BTCKey) {
        self.internalKey = internalKey
        self.externalKey = externalKey
    }
    
}