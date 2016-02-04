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
    let service: CBService
    let readCharacteristic: CBCharacteristic
    let writeCharacteristic: CBCharacteristic
    let writeByteSize = 20
    
    // MARK: Initialization
    
    init(name: String, service: CBService, readCharacteristic: CBCharacteristic, writeCharacteristic: CBCharacteristic) {
        self.name = name
        self.service = service
        self.readCharacteristic = readCharacteristic
        self.writeCharacteristic = writeCharacteristic
    }
    
}