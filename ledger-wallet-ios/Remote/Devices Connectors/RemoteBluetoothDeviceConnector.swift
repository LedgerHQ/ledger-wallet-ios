//
//  RemoteBluetoothDeviceConnector.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 01/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteBluetoothDeviceConnector: RemoteDeviceConnectorType {
    
    weak var delegate: RemoteDeviceConnectorDelegate?
    let transportType = RemoteTransportType.Bluetooth
    var connectedDevice: RemoteDeviceType? {
        return nil
    }
    var connectionState: RemoteDeviceConnectorState {
        return state
    }
    private var currentDevice: RemoteDeviceType?
    private var state: RemoteDeviceConnectorState = .Disconnected
    
    // MARK: Connection management
    
    func connectDevice(device: RemoteDeviceType) {
        
    }
    
    func disconnectDevice() {
        
    }
    
    private func
    
    // MARK: Initialization
    
    init(servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue) {
        
    }
    
}