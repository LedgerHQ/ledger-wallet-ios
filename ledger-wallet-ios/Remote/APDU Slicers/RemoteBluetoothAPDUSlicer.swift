//
//  RemoteBluetoothAPDUSlicer.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteBluetoothAPDUSlicer: RemoteAPDUSlicerType {
    
    let transportType = RemoteTransportType.Bluetooth
    private static let sliceAPDUCommandByte: UInt8 = 0x05
    private static let sliceAPDUCommandBytesLength = 1
    private static let sliceIndexBytesLength = 2
    private static let sliceAPDULengthBytesLength = 2
    
    func sliceFromData(data: NSData) -> RemoteAPDUSlice? {
        guard data.length > sliceHeaderBytesLengthAtIndex(1) else { return nil }
        guard let index = sliceIndexFromData(data) else { return nil }
        
        return RemoteAPDUSlice(index: index, data: data)
    }
    
    func sliceAPDU(APDU: RemoteAPDU, maxBytesLength: Int) -> [RemoteAPDUSlice] {
        var slices: [RemoteAPDUSlice] = []
        
        for i in 0...Int(UInt16.max) {
            guard let slice = sliceAtIndex(i, APDU: APDU, maxBytesLength: maxBytesLength) else {
                return slices
            }
            slices.append(slice)
        }
        return slices
    }
    
    func joinSlices(slices: [RemoteAPDUSlice]) -> RemoteAPDU? {
        guard slices.count > 0 else { return nil }
        let sortedSlices = slices.sort({ $0.0.index < $0.1.index })
        guard slicesAreCondigous(sortedSlices) else { return nil }
        
        guard let firstSlice = sortedSlices.first else { return nil }
        guard let totalBytesLength = APDUBytesLengthFromSlice(firstSlice) where totalBytesLength > 0 else { return nil }
        guard totalBytesLength > 0 && totalBytesLength <= Int(UInt16.max) else { return nil }
        guard let APDUData = NSMutableData(capacity: totalBytesLength) else { return nil }
        
        for slice in sortedSlices {
            guard let data = sliceDataFromSlice(slice) else { return nil }
            APDUData.appendData(data)
        }
        guard APDUData.length == totalBytesLength else { return nil }
        return RemoteAPDU(responseData: APDUData)
    }
    
    private func sliceDataFromSlice(slice: RemoteAPDUSlice) -> NSData? {
        let headerBytesLength = sliceHeaderBytesLengthAtIndex(slice.index)
        guard slice.data.length - headerBytesLength > 0 else { return nil }
        
        return slice.data.subdataWithRange(NSMakeRange(headerBytesLength, slice.data.length - headerBytesLength))
    }
    
    private func APDUBytesLengthFromSlice(slice: RemoteAPDUSlice) -> Int? {
        guard slice.index == 0 && slice.data.length >= sliceHeaderBytesLengthAtIndex(slice.index) else { return nil }
        
        let lengthBytes = slice.data.subdataWithRange(NSMakeRange(self.dynamicType.sliceAPDUCommandBytesLength + self.dynamicType.sliceIndexBytesLength, self.dynamicType.sliceAPDULengthBytesLength))
        var APDULength: UInt16 = 0
        lengthBytes.getBytes(&APDULength, length: lengthBytes.length)
        APDULength = CFSwapInt16BigToHost(APDULength)
        return Int(APDULength)
    }
    
    private func sliceIndexFromData(data: NSData) -> Int? {
        guard data.length > sliceHeaderBytesLengthAtIndex(1) else { return nil }

        let indexBytes = data.subdataWithRange(NSMakeRange(self.dynamicType.sliceAPDUCommandBytesLength, self.dynamicType.sliceIndexBytesLength))
        var index: UInt16 = 0
        indexBytes.getBytes(&index, length: indexBytes.length)
        index = CFSwapInt16BigToHost(index)
        return Int(index)
    }
    
    private func slicesAreCondigous(slices: [RemoteAPDUSlice]) -> Bool {
        var index = 0
        var slices = slices
        
        while slices.count > 0 {
            let firstSlice = slices.removeFirst()
            
            if firstSlice.index != index {
                return false
            }
            index += 1
        }
        return true
    }
    
    private func sliceAtIndex(index: Int, APDU: RemoteAPDU, maxBytesLength: Int) -> RemoteAPDUSlice? {
        guard maxBytesLength > 0 && APDU.data.length > 0 else { return nil }
        
        let data = NSMutableData()
        
        // append header
        data.appendData(sliceHeaderAtIndex(index, APDU: APDU))
        
        // append data
        guard let sliceData = sliceDataAtIndex(index, APDU: APDU, maxBytesLength: maxBytesLength) else {
            return nil
        }
        data.appendData(sliceData)
        return RemoteAPDUSlice(index: index, data: data)
    }
    
    private func sliceHeaderBytesLengthAtIndex(index: Int) -> Int {
        if index == 0 {
            return 5
        }
        return 3
    }
    
    private func sliceHeaderAtIndex(index: Int, APDU: RemoteAPDU) -> NSData {
        let data = NSMutableData()
        
        // append APDU flag 0x05, 1 byte
        data.appendBytes([self.dynamicType.sliceAPDUCommandByte], length: self.dynamicType.sliceAPDUCommandBytesLength)
        
        // append sequence number, big endian, 2 bytes
        var sequence = CFSwapInt16HostToBig(UInt16(index))
        withUnsafePointer(&sequence) {
            data.appendBytes($0, length: self.dynamicType.sliceIndexBytesLength)
        }
        
        // append APDU bytes length, big endian, 2 bytes
        if index == 0 {
            var length = CFSwapInt16HostToBig(UInt16(APDU.data.length))
            withUnsafePointer(&length) {
                data.appendBytes($0, length: self.dynamicType.sliceAPDULengthBytesLength)
            }
        }
        return data
    }
    
    private func sliceDataAtIndex(index: Int, APDU: RemoteAPDU, maxBytesLength: Int) -> NSData? {
        guard maxBytesLength > 0 && APDU.data.length > 0 else { return nil }

        var bytesCount = 0
        for i in 0...index {
            let remainingDataLength = maxBytesLength - sliceHeaderBytesLengthAtIndex(i)
            guard remainingDataLength > 0 else { return nil }
            let dataLength = min(APDU.data.length - bytesCount, remainingDataLength)
            guard dataLength > 0 else { return nil }
            
            if i == index {
                return APDU.data.subdataWithRange(NSMakeRange(bytesCount, dataLength))
            }
            bytesCount += dataLength
        }
        return nil
    }
    
}