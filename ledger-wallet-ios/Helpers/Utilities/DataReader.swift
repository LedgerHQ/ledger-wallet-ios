//
//  DataReader.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 11/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class DataReader {
    
    private let internalData: NSMutableData
    
    var remainingBytesLength: Int {
        return internalData.length
    }
    
    // MARK: Read methods
    
    func readNextInt8() -> Int8? {
        return readNextInteger()
    }
    
    func readNextUInt8() -> UInt8? {
        return readNextInteger()
    }
    
    func readNextBigEndianUInt16() -> UInt16? {
        return readNextInteger(bigEndian: true)
    }

    func readNextLittleEndianUInt16() -> UInt16? {
        return readNextInteger(bigEndian: false)
    }
    
    func readNextBigEndianInt16() -> Int16? {
        return readNextInteger(bigEndian: true)
    }
    
    func readNextLittleEndianInt16() -> Int16? {
        return readNextInteger(bigEndian: false)
    }
    
    func readNextBigEndianUInt32() -> UInt32? {
        return readNextInteger(bigEndian: true)
    }
    
    func readNextLittleEndianUInt32() -> UInt32? {
        return readNextInteger(bigEndian: false)
    }
    
    func readNextBigEndianInt32() -> Int32? {
        return readNextInteger(bigEndian: true)
    }
    
    func readNextLittleEndianInt32() -> Int32? {
        return readNextInteger(bigEndian: false)
    }
    
    func readNextBigEndianUInt64() -> UInt64? {
        return readNextInteger(bigEndian: true)
    }
    
    func readNextLittleEndianUInt64() -> UInt64? {
        return readNextInteger(bigEndian: false)
    }
    
    func readNextBigEndianInt64() -> Int64? {
        return readNextInteger(bigEndian: true)
    }
    
    func readNextLittleEndianInt64() -> Int64? {
        return readNextInteger(bigEndian: false)
    }
    
    func readNextAvailableData() -> NSData? {
        return readNextDataOfLength(remainingBytesLength)
    }
    
    func readNextDataOfLength(length: Int) -> NSData? {
        guard internalData.length >= length else { return nil }
        
        let data = internalData.subdataWithRange(NSMakeRange(0, length))
        internalData.replaceBytesInRange(NSMakeRange(0, length), withBytes: nil, length: 0)
        return data
    }

    // MARK: Internal methods
    
    private func readNextInteger<T: IntegerType>() -> T? {
        guard let data = readNextDataOfLength(sizeof(T)) else { return nil }
        
        var value: T = 0
        data.getBytes(&value, length: sizeof(T))
        return value
    }
    
    private func readNextInteger<T: EndianConvertible>(bigEndian bigEndian: Bool) -> T? {
        guard let data = readNextDataOfLength(sizeof(T)) else { return nil }
        
        var value: T = 0
        data.getBytes(&value, length: sizeof(T))
        return bigEndian ? value.bigEndian : value.littleEndian
    }
    
    // MARK: Initialization
    
    init(data: NSData) {
        self.internalData = NSMutableData(data: data)
    }
    
}