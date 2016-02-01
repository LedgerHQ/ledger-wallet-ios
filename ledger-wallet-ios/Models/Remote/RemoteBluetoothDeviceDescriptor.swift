//
//  RemoteBluetoothDeviceDescriptor.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation
import CoreBluetooth

final class RemoteBluetoothDeviceDescriptor: RemoteDeviceDescriptorType {
    
    let name: String
    let transportType = RemoteTransportType.Bluetooth
    let services: [CBService]
    
    // MARK: Initialization
    
    init(name: String, services: [CBService]) {
        self.name = name
        self.services = services
    }
    
}