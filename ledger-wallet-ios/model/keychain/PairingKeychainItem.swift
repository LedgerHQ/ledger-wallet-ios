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
    override class var itemClass: String { return kSecClassGenericPassword as! String }
    override var isValid: Bool { return super.isValid && pairingId != nil && pairingKey != nil && dongleName != nil }
    
    var pairingKey: Crypto.Key? {
        get {
            if let value = valueForKey("pairing_key") {
                return Crypto.Key(symmetricKey: Crypto.Encode.dataFromBase16String(value))
            }
            return nil
        }
        set {
            if let pairingKey = newValue?.symmetricKey {
                setValue(Crypto.Encode.base16StringFromData(pairingKey), forKey: "pairing_key")
            }
            else {
                setValue(nil, forKey: "pairing_key")
            }
        }
    }
    var pairingId: String? {
        get {
            return valueForKey("pairing_id")
        }
        set {
            setValue(newValue, forKey: "pairing_id")
        }
    }
    var dongleName: String? {
        get {
            return valueForKey("dongle_name")
        }
        set {
            setValue(newValue, forKey: "dongle_name")
        }
    }
    var deviceToken: NSData? {
        get {
            if let value = valueForKey("device_token") {
                return Crypto.Encode.dataFromBase16String(value)
            }
            return nil
        }
        set {
            if let deviceToken = newValue {
                setValue(Crypto.Encode.base16StringFromData(deviceToken), forKey: "device_token")
            }
            else {
                setValue(nil, forKey: "device_token")
            }
        }
    }
}

extension PairingKeychainItem: Equatable {

}

func ==(lhs: PairingKeychainItem, rhs: PairingKeychainItem) -> Bool {
    return lhs.pairingId == rhs.pairingId
}