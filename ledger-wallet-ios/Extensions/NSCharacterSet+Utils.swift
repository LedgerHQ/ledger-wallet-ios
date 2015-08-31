//
//  NSCharacterSet+Utils.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 21/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

extension NSCharacterSet {
    
    class func base58CharacterSet() -> NSCharacterSet {
        return NSCharacterSet(charactersInString: "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")
    }
    
    class func base16CharacterSet() -> NSCharacterSet {
        return NSCharacterSet(charactersInString: "0123456789ABCDEFabcdef")
    }

    
}