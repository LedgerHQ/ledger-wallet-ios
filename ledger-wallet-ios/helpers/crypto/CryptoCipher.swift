//
//  CryptoCipher.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 05/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

extension Crypto {

    class Cipher {
        
        class func tripleDESCBCFromData(data: NSData, key1: NSData, key2: NSData, key3: NSData) -> NSData {
            return objCTripleDESCBCFromData(data, key1, key2, key3)
        }
        
        class func dataFromTripleDESCBC(data: NSData, key1: NSData, key2: NSData, key3: NSData) -> NSData {
            return objCDataFromTripleDESCBC(data, key1, key2, key3)
        }
        
    }

}