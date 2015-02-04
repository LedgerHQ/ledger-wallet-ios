//
//  CryptoHash.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

extension Crypto {
 
    class Hash {
        
        class func SHA256FromData(data: NSData) -> NSData {
            let length = Int(CC_SHA256_DIGEST_LENGTH)
            var hash = [UInt8](count: length, repeatedValue: 0)
            CC_SHA256(data.bytes, CC_LONG(data.length), &hash)
            return NSData(bytes: hash, length: length)
        }
        
        class func SHA512FromData(data: NSData) -> NSData {
            let length = Int(CC_SHA512_DIGEST_LENGTH)
            var hash = [UInt8](count: length, repeatedValue: 0)
            CC_SHA512(data.bytes, CC_LONG(data.length), &hash)
            return NSData(bytes: hash, length: length)
        }
        
    }
    
}