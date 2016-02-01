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
    
    let name: String?
    let transportType = RemoteTransportType.Bluetooth
    let peripheral: CBPeripheral
    let descriptor: RemoteBluetoothDeviceDescriptor
    
    // MARK: Initialization
    
    init(name: String?, peripheral: CBPeripheral, descriptor: RemoteBluetoothDeviceDescriptor) {
        self.name = name
        self.peripheral = peripheral
        self.descriptor = descriptor
    }
    
}