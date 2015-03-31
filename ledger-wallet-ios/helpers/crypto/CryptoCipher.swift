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
        
        class func tripleDESCBCFromData(data: NSData, key1: Crypto.Key, key2: Crypto.Key, key3: Crypto.Key) -> NSData {
            return objCTripleDESCBCFromData(data, key1.symmetricKey, key2.symmetricKey, key3.symmetricKey)
        }
        
        class func dataFromTripleDESCBC(data: NSData, key1: Crypto.Key, key2: Crypto.Key, key3: Crypto.Key) -> NSData {
            return objCDataFromTripleDESCBC(data, key1.symmetricKey, key2.symmetricKey, key3.symmetricKey)
        }
        
    }

}