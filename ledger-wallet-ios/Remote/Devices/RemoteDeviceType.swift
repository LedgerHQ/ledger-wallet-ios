//
//  RemoteDeviceType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol RemoteDeviceType {

    var uid: String { get }
    var name: String { get }
    var transportType: RemoteTransportType { get }
    var descriptor: RemoteDeviceDescriptorType { get }
    var devicesManager: RemoteDevicesManagerType { get }
    
    var isConnected: Bool { get }
    var isConnecting: Bool { get }
    var isDisconnected: Bool { get }
    
}

extension RemoteDeviceType {
    
    var isConnected: Bool { return devicesManager.activeDevice?.uid == self.uid && devicesManager.connectionState == .Connected }
    var isConnecting: Bool { return devicesManager.activeDevice?.uid == self.uid && devicesManager.connectionState == .Connecting }
    var isDisconnected: Bool { return devicesManager.activeDevice?.uid != self.uid }
    
}