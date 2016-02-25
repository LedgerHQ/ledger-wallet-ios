//
//  DataWriter.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class DataWriter {
    
    private let internalData: NSMutableData
    
    var data: NSData {
        return internalData.copy() as! NSData
    }
    
    var dataLength: Int {
        return internalData.length
    }
    
    // MARK: Write methods

    func writeNextUInt8(value: UInt8) {
        writeNextInteger(value)
    }
    
    func writeNextInt8(value: Int8) {
        writeNextInteger(value)
    }
    
    func writeNextBigEndianUInt16(value: UInt16) {
        writeNextInteger(value, bigEndian: true)
    }
    
    func writeNextLittleEndianUInt16(value: UInt16) {
        writeNextInteger(value, bigEndian: false)
    }
    
    func writeNextBigEndianInt16(value: Int16) {
        writeNextInteger(value, bigEndian: true)
    }
    
    func writeNextLittleEndianInt16(value: Int16) {
        writeNextInteger(value, bigEndian: false)
    }
    
    func writeNextBigEndianUInt32(value: UInt32) {
        writeNextInteger(value, bigEndian: true)
    }

    func writeNextLittleEndianUInt32(value: UInt32) {
        writeNextInteger(value, bigEndian: false)
    }
    
    func writeNextBigEndianInt32(value: Int32) {
        writeNextInteger(value, bigEndian: true)
    }
    
    func writeNextLittleEndianInt32(value: Int32) {
        writeNextInteger(value, bigEndian: false)
    }
    
    func writeNextBigEndianUInt64(value: UInt64) {
        writeNextInteger(value, bigEndian: true)
    }
    
    func writeNextLittleEndianUInt64(value: UInt64) {
        writeNextInteger(value, bigEndian: false)
    }
    
    func writeNextBigEndianInt64(value: Int64) {
        writeNextInteger(value, bigEndian: true)
    }
    
    func writeNextLittleEndianInt64(value: Int64) {
        writeNextInteger(value, bigEndian: false)
    }
    
    func writeNextVarInteger(value: UInt64) {
        let parser = VarIntParser(value: value)
        if let data = parser.representativeBytes {
            writeNextData(data)
        }
    }
    
    func writeNextData(data: NSData) {
        internalData.appendData(data)
    }
    
    func writeNextReversedData(data: NSData) {
        guard let reversedData = BTCReversedData(data) else { return }
        writeNextData(reversedData)
    }
    
    private func writeNextInteger<T: IntegerType>(value: T) {
        var value = value
        internalData.appendBytes(&value, length: sizeof(T))
    }
    
    private func writeNextInteger<T: EndianConvertible>(value: T, bigEndian: Bool) {
        var value = value
        value = bigEndian ? value.bigEndian : value.littleEndian
        internalData.appendBytes(&value, length: sizeof(T))
    }
    
    // MARK: Initialization

    init() {
        self.internalData = NSMutableData()
    }
    
}