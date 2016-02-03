//
//  RemoteBluetoothDevice.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 01/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation
import CoreBluetooth

final class RemoteBluetoothDevice: NSObject, RemoteDeviceType {
    
    var uid: String { return "\(peripheral.identifier.UUIDString)" }
    let name: String
    let transportType = RemoteTransportType.Bluetooth
    let descriptor: RemoteDeviceDescriptorType
    let peripheral: CBPeripheral
    unowned let devicesManager: RemoteDevicesManagerType
    weak var readCharacteristic: CBCharacteristic?
    weak var writeCharacteristic: CBCharacteristic?
    
    // MARK: Initialization
    
    init(name: String, descriptor: RemoteDeviceDescriptorType, peripheral: CBPeripheral, devicesManager: RemoteDevicesManagerType) {
        self.name = name
        self.descriptor = descriptor
        self.peripheral = peripheral
        self.devicesManager = devicesManager
    }
    
}