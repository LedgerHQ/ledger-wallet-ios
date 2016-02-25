//
//  NSData+Utils.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/09/15.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

extension NSData {
    
    var splitData:(NSData, NSData)? {
        guard self.length > 0 && self.length % 2 == 0 else {
            return nil
        }
        let partLength = self.length / 2
        return (self.subdataWithRange(NSMakeRange(0, partLength)), self.subdataWithRange(NSMakeRange(partLength, partLength)))
    }
    
    var bytesArray: [UInt8] {
        let count = self.length / sizeof(UInt8)
        var bytesArray = [UInt8](count: count, repeatedValue: 0)
        self.getBytes(&bytesArray, length:count * sizeof(UInt8))
        return bytesArray
    }
    
    func XORWithData(data: NSData) -> NSData? {
        if (data.length == 0 || self.length == 0 || data.length != self.length) {
            return nil
        }
        
        let bytesFirst = UnsafePointer<UInt8>(data.bytes)
        let bytesSecond = UnsafePointer<UInt8>(self.bytes)
        let newData = NSMutableData(length: data.length)!
        let writableBytes = UnsafeMutablePointer<UInt8>(newData.mutableBytes)
        for i in 0..<data.length {
            writableBytes[i] = bytesFirst[i] ^ bytesSecond[i]
        }
        return newData
    }
    
    func tripeDESCBCWithKeys(key1 key1: NSData, key2: NSData, key3: NSData, encrypt: Bool) -> NSData? {
        let outData = NSMutableData(length: self.length + kCCKeySize3DES)!
        var writtenBytes: Int = 0
        let key = NSMutableData(data: key1)
        key.appendData(key2)
        key.appendData(key3)
        let result = CCCrypt(UInt32(encrypt ? kCCEncrypt : kCCDecrypt), UInt32(kCCAlgorithm3DES), 0, key.bytes, key.length, nil, self.bytes, self.length, outData.mutableBytes, outData.length, &writtenBytes)
        guard Int(result) == Int(kCCSuccess) else { return nil }
        return outData.subdataWithRange(NSMakeRange(0, writtenBytes))
    }
    
    func splitWithSize(size: Int) -> [NSData] {
        let mutableData = NSMutableData(data: self)
        var slices: [NSData] = []
        
        while mutableData.length > 0 {
            let range = NSMakeRange(0, min(size, mutableData.length))
            slices.append(mutableData.subdataWithRange(range))
            mutableData.replaceBytesInRange(range, withBytes: nil, length: 0)
        }
        return slices
    }
    
}