//
//  VarIntParser.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/10/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class VarIntParser {
    
    private let data: NSData
    
    var valid: Bool {
        return bytesCount > 0 && data.length >= bytesCount
    }
    
    var bytesCount: Int {
        guard data.length > 0 else { return 0 }
        
        let firstByteBuffer = UnsafeMutablePointer<UInt8>.alloc(1)
        data.getBytes(firstByteBuffer, length: 1)
        defer { firstByteBuffer.dealloc(1) }
        
        switch firstByteBuffer.memory {
        case 0...0xFC: return 1
        case 0xFD: return 3
        case 0xFE: return 5
        case 0xFF: return 9
        default: return 0
        }
    }
    
    var representativeBytes: NSData? {
        guard valid else { return nil }
        
        return data.subdataWithRange(NSMakeRange(0, bytesCount))
    }
    
    var unsignedInt64Value: UInt64? {
        guard valid else { return nil }
        
        let bytesCount = self.bytesCount - 1
        var value: UInt64 = 0
        data.getBytes(&value, range: NSMakeRange(bytesCount == 0 ? 0 : 1, bytesCount == 0 ? 1 : bytesCount))
        return CFSwapInt64LittleToHost(UInt64(value))
    }

    // MARK: Initialization
    
    init(data: NSData) {
        self.data = data
    }
    
    convenience init(value: UInt64) {
        let writer = DataWriter()
        
        if value < 0xFD {
            writer.writeNextUInt8(UInt8(value))
        }
        else if value <= 0xFFFF {
            writer.writeNextUInt8(0xFD)
            writer.writeNextLittleEndianUInt16(UInt16(value))
        }
        else if value <= 0xFFFFFFFF {
            writer.writeNextUInt8(0xFE)
            writer.writeNextLittleEndianUInt32(UInt32(value))
        }
        else {
            writer.writeNextUInt8(0xFF)
            writer.writeNextLittleEndianUInt64(value)
        }
        self.init(data: writer.data)
    }
    
}