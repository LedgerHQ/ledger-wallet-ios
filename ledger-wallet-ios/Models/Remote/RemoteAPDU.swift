//
//  RemoteAPDU.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct RemoteAPDU {
    
    static let minimumRequestBytesLength = 6
    static let minimumResponseBytesLength = 2
    let data: NSData
    let isResponse: Bool
    
    var statusError: RemoteDeviceError? {
        guard isResponse else { return nil }
        guard let statusData = statusData else { return .InvalidResponse }
        return RemoteDeviceError(statusData: statusData)
    }
    
    var responseData: NSData? {
        guard isResponse else { return nil }
        guard data.length > self.dynamicType.minimumResponseBytesLength else { return nil }
        return data.subdataWithRange(NSMakeRange(0, data.length - self.dynamicType.minimumResponseBytesLength))
    }
    
    var statusData: NSData? {
        guard isResponse else { return nil }
        guard data.length >= self.dynamicType.minimumResponseBytesLength else { return nil }
        return data.subdataWithRange(NSMakeRange(data.length - self.dynamicType.minimumResponseBytesLength, self.dynamicType.minimumResponseBytesLength))
    }

    // MARK: Initialization
    
    init?(classByte: UInt8, instruction: UInt8, p1: UInt8, p2: UInt8, data: NSData?, responseLength: UInt8) {
        let finalData = NSMutableData()
        
        finalData.appendByte(classByte)
        finalData.appendByte(instruction)
        finalData.appendByte(p1)
        finalData.appendByte(p2)
        
        // data
        if let data = data {
            guard data.length >= 0 && data.length <= Int(UInt8.max) else {
                return nil
            }
            finalData.appendByte(UInt8(data.length))
            finalData.appendData(data)
        }
        else {
            finalData.appendByte(0x00)
        }
        
        finalData.appendByte(responseLength)
        self.init(requestData: finalData)
    }
    
    init?(requestData: NSData) {
        guard requestData.length >= self.dynamicType.minimumRequestBytesLength && requestData.length <= Int(UInt16.max) else {
            return nil
        }
        
        self.isResponse = false
        self.data = requestData
    }
    
    init?(responseData: NSData) {
        guard responseData.length >= self.dynamicType.minimumResponseBytesLength && responseData.length <= Int(UInt16.max) else {
            return nil
        }
        
        self.isResponse = true
        self.data = responseData
    }

}