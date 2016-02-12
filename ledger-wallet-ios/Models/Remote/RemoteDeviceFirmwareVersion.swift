//
//  RemoteDeviceFirmwareVersion.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct RemoteDeviceFirmwareVersion {
    
    static let requiredBytesLength = 8
    
    let majorVersion: UInt8
    let minorVersion: UInt8
    let patchVersion: UInt8
    let loaderMajorVersion: UInt8
    let loaderMinorVersion: UInt8
    let architecture: UInt8
    let featuresFlag: UInt8
    let setupFlag: UInt8
    
    init?(versionData: NSData) {
        guard versionData.length == self.dynamicType.requiredBytesLength else {
            return nil
        }
        
        let reader = DataReader(data: versionData)
        guard let
            featuresFlag = reader.readNextUInt8(),
            architecture = reader.readNextUInt8(),
            majorVersion = reader.readNextUInt8(),
            minorVersion = reader.readNextUInt8(),
            patchVersion = reader.readNextUInt8(),
            loaderMajorVersion = reader.readNextUInt8(),
            loaderMinorVersion = reader.readNextUInt8(),
            setupFlag = reader.readNextUInt8()
        else {
            return nil
        }
        self.featuresFlag = featuresFlag
        self.architecture = architecture
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.patchVersion = patchVersion
        self.loaderMajorVersion = loaderMajorVersion
        self.loaderMinorVersion = loaderMinorVersion
        self.setupFlag = setupFlag
    }
    
}