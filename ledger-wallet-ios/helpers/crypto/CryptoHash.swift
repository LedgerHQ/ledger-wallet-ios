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
        
        class func XORFromDataPair(data: NSData, _ otherData: NSData) -> NSData {
            if (data.length == 0 || otherData.length == 0 || data.length != otherData.length) {
                return NSData()
            }
            
            let bytesFirst = UnsafePointer<UInt8>(data.bytes)
            let bytesSecond = UnsafePointer<UInt8>(otherData.bytes)
            let newData = NSMutableData(length: data.length)!
            let writableBytes = UnsafeMutablePointer<UInt8>(newData.mutableBytes)
            for i in 0..<data.length {
                writableBytes[i] = bytesFirst[i] ^ bytesSecond[i]
            }
            return newData
        }
        
    }
    
}