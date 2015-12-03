//
//  PairingKeychainItem.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class PairingKeychainItem: BaseKeychainItem, Equatable {
    
    override class var serviceIdentifier: String { return "co.ledger.ledgerwallet.pairing" }
    override var valid: Bool { return super.valid && pairingId != nil && pairingKey != nil && dongleName != nil }
    
    var pairingKey: NSData? {
        get {
            if let value = valueForKey("pairing_key") {
                return BTCDataFromHex(value)
            }
            return nil
        }
        set {
            if let pairingKey = newValue {
                setValue(BTCHexFromData(pairingKey), forKey: "pairing_key")
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
                return BTCDataFromHex(value)
            }
            return nil
        }
        set {
            if let deviceToken = newValue {
                setValue(BTCHexFromData(deviceToken), forKey: "device_token")
            }
            else {
                setValue(nil, forKey: "device_token")
            }
        }
    }

}

func ==(lhs: PairingKeychainItem, rhs: PairingKeychainItem) -> Bool {
    return lhs.pairingId == rhs.pairingId
}