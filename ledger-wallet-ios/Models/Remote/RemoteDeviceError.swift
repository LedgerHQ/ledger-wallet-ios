//
//  RemoteDeviceError.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

enum RemoteDeviceError: ErrorType {
    
    case RemoteDisconnection
    case DoesNotMatchDescriptor
    case UnableToBind
    case UnableToConnect
    case UnableToAuthentify
    case UnableToRead
    case UnableToWrite
    case CancelledTask
    case NotConnected
    case InvalidLength
    case InvalidAccessRights
    case InvalidRequest
    case InvalidResponse
    case InvalidParameters
    case FileNotFound
    case NotImplemented
    case TechnicalProblem(byte: UInt8)
    case Unknown
    
    init?(statusData: NSData) {
        guard statusData.length == RemoteAPDU.minimumResponseBytesLength else { return nil }
        
        if let split = statusData.splitData where split.0 == BTCDataFromHex("6F") {
            var byte: UInt8 = 0
            split.1.getBytes(&byte, length: 1)
            self = .TechnicalProblem(byte: byte)
            return
        }
        
        switch statusData {
        case BTCDataFromHex("9000"):
            return nil
        case BTCDataFromHex("6700"):
            self = .InvalidLength
        case BTCDataFromHex("6982"):
            self = .InvalidAccessRights
        case BTCDataFromHex("6A80"):
            self = .InvalidRequest
        case BTCDataFromHex("6A82"):
            self = .FileNotFound
        case BTCDataFromHex("6B00"):
            self = .InvalidParameters
        case BTCDataFromHex("6D00"):
            self = .NotImplemented
        default:
            break
        }
        self = Unknown
    }
    
}